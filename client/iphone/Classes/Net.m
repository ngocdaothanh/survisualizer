#import "Net.h"

@implementation Net

- (id) init {
	connections = CFDictionaryCreateMutable(NULL, 0, NULL, NULL);
	return self;
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
    NSLog(@"Added connection.");
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
    NSLog(@"Connection closed.");
}

- (void)handleNewConnectionFromAddress:(NSData *)addr inputStream:(NSInputStream *)istr outputStream:(NSOutputStream *)ostr {
    [self setupInputStream:istr outputStream:ostr];
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)streamEvent {
    NSInputStream * istream;
    NSOutputStream * ostream;
    switch(streamEvent) {
        case NSStreamEventHasBytesAvailable:;
            istream = (NSInputStream *)aStream;
            ostream = (NSOutputStream *)CFDictionaryGetValue(connections, istream);
            
            uint8_t buffer[2048];
            int actuallyRead = [istream read:(uint8_t *)buffer maxLength:2048];
            if (actuallyRead > 0) {
                //[ostream write:buffer maxLength:actuallyRead];
            }
			break;
        case NSStreamEventEndEncountered:;
            istream = (NSInputStream *)aStream;
            ostream = nil;
            if (CFDictionaryGetValueIfPresent(connections, istream, (const void **)&ostream)) {
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

- (void)broadcast:(uint8_t *)buffer size:(unsigned int)bufferSize {
	int count = CFDictionaryGetCount(connections);
	if (!count) {
		return;
	}

	NSInputStream * istreams[count];
    NSOutputStream * ostreams[count];
	CFDictionaryGetKeysAndValues(connections, (const void **) istreams, (const void **) ostreams);
	for (int i = 0; i < count; i++) {
		int bytesWritten = 0;
		while (bytesWritten < bufferSize) {
			bytesWritten += [ostreams[i] write:(buffer + bytesWritten) maxLength:(bufferSize - bytesWritten)];
		}
	}
}

@end
