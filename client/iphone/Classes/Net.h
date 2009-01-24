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

- (BOOL)connected;
- (uint8_t *)readBytes:(NSInputStream *)istream length:(NSUInteger)length;
- (int)readInt:(NSInputStream *)istream;
- (void)sendBytes:(uint8_t *)bytes length:(unsigned int)length;
- (void)sendInt:(int)value;
@end
