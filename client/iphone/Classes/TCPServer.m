#import "TCPServer.h"
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>

NSString * const TCPServerErrorDomain = @"TCPServerErrorDomain";

@implementation TCPServer

- (id)init {
	return self;
}

- (void)dealloc {
	[self stop];
	[domain release];
	[name release];
	[type release];
	[super dealloc];
}

- (id)delegate {
	return delegate;
}

- (void)setDelegate:(id)value {
	delegate = value;
}

- (NSString *)domain {
	return domain;
}

- (void)setDomain:(NSString *)value {
	if (domain != value) {
		[domain release];
		domain = [value copy];
	}
}

- (NSString *)name {
	return name;
}

- (void)setName:(NSString *)value {
	if (name != value) {
		[name release];
		name = [value copy];
	}
}

- (NSString *)type {
	return type;
}

- (void)setType:(NSString *)value {
	if (type != value) {
		[type release];
		type = [value copy];
	}
}

- (uint16_t)port {
	return port;
}

- (void)setPort:(uint16_t)value {
	port = value;
}

- (void)handleNewConnectionFromAddress:(NSData *)addr inputStream:(NSInputStream *)istr outputStream:(NSOutputStream *)ostr {
	// If the delegate implements the delegate method, call it	
	if (delegate && [delegate respondsToSelector:@selector(TCPServer:didReceiveConnectionFrom:inputStream:outputStream:)]) { 
		[delegate TCPServer:self didReceiveConnectionFromAddress:addr inputStream:istr outputStream:ostr];
	}
}

/**
 * This function is called by CFSocket when a new connection comes in.
 * We gather some data here, and convert the function call to a method
 * invocation on TCPServer.
 */
static void TCPServerAcceptCallBack(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) {
	TCPServer *server = (TCPServer *)info;
	if (kCFSocketAcceptCallBack == type) { 
		// For an AcceptCallBack, the data parameter is a pointer to a CFSocketNativeHandle
		CFSocketNativeHandle nativeSocketHandle = *(CFSocketNativeHandle *)data;
		uint8_t name[SOCK_MAXADDRLEN];
		socklen_t namelen = sizeof(name);
		NSData *peer = nil;
		if (0 == getpeername(nativeSocketHandle, (struct sockaddr *)name, &namelen)) {
			peer = [NSData dataWithBytes:name length:namelen];
		}
		CFReadStreamRef readStream = NULL;
	CFWriteStreamRef writeStream = NULL;
		CFStreamCreatePairWithSocket(kCFAllocatorDefault, nativeSocketHandle, &readStream, &writeStream);
		if (readStream && writeStream) {
			CFReadStreamSetProperty(readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
			CFWriteStreamSetProperty(writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
			[server handleNewConnectionFromAddress:peer inputStream:(NSInputStream *)readStream outputStream:(NSOutputStream *)writeStream];
		} else {
			// On any failure, need to destroy the CFSocketNativeHandle 
			// since we are not going to use it any more
			close(nativeSocketHandle);
		}
		if (readStream) CFRelease(readStream);
		if (writeStream) CFRelease(writeStream);
	}
}

- (BOOL)start:(NSError **)error {
	CFSocketContext socketCtxt = {0, self, NULL, NULL, NULL};
	ipv4socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketAcceptCallBack, (CFSocketCallBack)&TCPServerAcceptCallBack, &socketCtxt);

	if (NULL == ipv4socket) {
		if (error) *error = [[NSError alloc] initWithDomain:TCPServerErrorDomain code:kTCPServerNoSocketsAvailable userInfo:nil];
		if (ipv4socket) CFRelease(ipv4socket);
		ipv4socket = NULL;
		return NO;
	}

	int yes = 1;
	setsockopt(CFSocketGetNative(ipv4socket), SOL_SOCKET, SO_REUSEADDR, (void *)&yes, sizeof(yes));

	// Set up the IPv4 endpoint; if port is 0, this will cause the kernel to choose a port for us
	struct sockaddr_in addr4;
	memset(&addr4, 0, sizeof(addr4));
	addr4.sin_len = sizeof(addr4);
	addr4.sin_family = AF_INET;
	addr4.sin_port = htons(port);
	addr4.sin_addr.s_addr = htonl(INADDR_ANY);
	NSData *address4 = [NSData dataWithBytes:&addr4 length:sizeof(addr4)];

	if (kCFSocketSuccess != CFSocketSetAddress(ipv4socket, (CFDataRef)address4)) {
		if (error) *error = [[NSError alloc] initWithDomain:TCPServerErrorDomain code:kTCPServerCouldNotBindToIPv4Address userInfo:nil];
		if (ipv4socket) CFRelease(ipv4socket);
		ipv4socket = NULL;
		return NO;
	}
	
	if (0 == port) {
		// Now that the binding was successful, we get the port number 
		// -- we will need it for the v6 endpoint and for the NSNetService
		NSData *addr = [(NSData *)CFSocketCopyAddress(ipv4socket) autorelease];
		memcpy(&addr4, [addr bytes], [addr length]);
		port = ntohs(addr4.sin_port);
	}

	// Set up the run loop sources for the sockets
	CFRunLoopRef cfrl = CFRunLoopGetCurrent();
	CFRunLoopSourceRef source4 = CFSocketCreateRunLoopSource(kCFAllocatorDefault, ipv4socket, 0);
	CFRunLoopAddSource(cfrl, source4, kCFRunLoopCommonModes);
	CFRelease(source4);

	// We can only publish the service if we have a type to publish with
	if (nil != type) {
		NSString *publishingDomain = domain ? domain : @"";
		NSString *publishingName = nil;
		if (nil != name) {
			publishingName = name;
		} else {
			NSString * thisHostName = [[NSProcessInfo processInfo] hostName];
			if ([thisHostName hasSuffix:@".local"]) {
				publishingName = [thisHostName substringToIndex:([thisHostName length] - 6)];
			}
		}
		netService = [[NSNetService alloc] initWithDomain:publishingDomain type:type name:publishingName port:port];
		[netService publish];
	}

	return YES;
}

- (BOOL)stop {
	[netService stop];
	[netService release];
	netService = nil;
	CFSocketInvalidate(ipv4socket);
	CFRelease(ipv4socket);
	ipv4socket = NULL;
	return YES;
}

@end
