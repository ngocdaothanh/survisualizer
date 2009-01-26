#import "Net.h"
#import "EAGLView.h"

@implementation Net

- (id)initWithView:(EAGLView *)view {
	if (self = [self init]) {
		connections = CFDictionaryCreateMutable(NULL, 0, NULL, NULL);
		glView = [view retain];
	}
	return self;
}

- (void)dealloc {
	[glView autorelease];
	[super dealloc];
}

- (void)setupInputStream:(NSInputStream *)istream outputStream:(NSOutputStream *)ostream {
	[istream retain];
	[ostream retain];
	[istream setDelegate:self];
	[ostream setDelegate:self];
	[istream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[ostream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	CFDictionarySetValue(connections, istream, ostream);
	[istream open];
	[ostream open];
	NSLog(@"PTAM connected");
}

- (void)shutdownInputStream:(NSInputStream *)istream outputStream:(NSOutputStream *)ostream {
	[istream close];
	[ostream close];
	[istream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[ostream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[istream setDelegate:nil];
	[ostream setDelegate:nil];
	CFDictionaryRemoveValue(connections, istream);
	[istream release];
	[ostream release];
	NSLog(@"PTAM disconnected");
}

- (void)handleNewConnectionFromAddress:(NSData *)addr inputStream:(NSInputStream *)istr outputStream:(NSOutputStream *)ostr {
	[self setupInputStream:istr outputStream:ostr];
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)streamEvent {
	NSInputStream *istream;
	NSOutputStream *ostream;
	
	switch (streamEvent) {
		case NSStreamEventHasBytesAvailable:			
			istream = (NSInputStream *) aStream;
			[glView onReceive:istream];
			break;
			
		case NSStreamEventEndEncountered:
			istream = (NSInputStream *) aStream;
			ostream = nil;
			if (CFDictionaryGetValueIfPresent(connections, istream, (const void **) &ostream)) {
				[self shutdownInputStream:istream outputStream:ostream];
			}
			break;
			
		case NSStreamEventHasSpaceAvailable:
		case NSStreamEventErrorOccurred:
		case NSStreamEventOpenCompleted:
		case NSStreamEventNone:
		default:
			break;
	}
}

- (BOOL)isConnected {
	int count = CFDictionaryGetCount(connections);
	return (count > 0);
}

- (NSOutputStream *)ostream {	
	int count = CFDictionaryGetCount(connections);
	NSInputStream *istreams[count];
	NSOutputStream *ostreams[count];
	CFDictionaryGetKeysAndValues(connections, (const void **) istreams, (const void **) ostreams);
	return ostreams[0];
}

@end

// -----------------------------------------------------------------------------

@implementation NSInputStream(Receive)	

- (char *)receiveBytes:(int)length {
	char *ret = malloc(length);
	
	NSUInteger read = 0;
	while (read < length) {
		uint8_t *tmp = malloc(length - read);
		NSUInteger actuallyRead = [self read:tmp maxLength:(length - read)];
		memcpy(ret + read, tmp, actuallyRead);
		free(tmp);
		read += actuallyRead;
	}
	
	return ret;	
}

- (int)receiveInt {
	char *bytes = [self receiveBytes:sizeof(int)];
	int ret;
	char *p = (char *) &ret;
	for (int i = 0; i <  sizeof(int); i++) {
		p[i] = bytes[i];
	}
	free(bytes);
	return ret;	
}

- (float)receiveFloat {
	char *bytes = [self receiveBytes:sizeof(float)];
	float ret;
	char *p = (char *) &ret;
	for (int i = 0; i <  sizeof(float); i++) {
		p[i] = bytes[i];
	}
	free(bytes);
	return ret;		
}

@end

// -----------------------------------------------------------------------------

@implementation NSOutputStream(Send)

- (void)sendInt:(int)value {
	[self sendBytes:(uint8_t *) &value length:sizeof(int)];
}

- (void)sendBytes:(uint8_t *)bytes length:(NSUInteger)length {
	int bytesWritten = 0;
	while (bytesWritten < length) {
		bytesWritten += [self write:(bytes + bytesWritten) maxLength:(length - bytesWritten)];
	}
}

@end
