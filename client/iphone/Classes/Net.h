#import <Foundation/Foundation.h>
#import "TCPServer.h"

@class EAGLView;

@interface Net : TCPServer {
@private
	CFMutableDictionaryRef connections;
	EAGLView *glView;
	BOOL connected;
}

- (id)initWithView:(EAGLView *)glView;
- (void)handleNewConnectionFromAddress:(NSData *)addr inputStream:(NSInputStream *)istr outputStream:(NSOutputStream *)ostr;

- (BOOL)isConnected;
- (NSOutputStream *)ostream;

@end

// -----------------------------------------------------------------------------

@interface NSInputStream(Receive)

- (char *)receiveBytes:(int)length;
- (int)receiveInt;
- (float)receiveFloat;

@end

// -----------------------------------------------------------------------------

@interface NSOutputStream(Send)

- (void)sendBytes:(uint8_t *)bytes length:(unsigned int)length;
- (void)sendInt:(int)value;

@end
