#import <Foundation/Foundation.h>
#import "TCPServer.h"

@interface Net : TCPServer {
@private
    CFMutableDictionaryRef connections;
}

- (void)handleNewConnectionFromAddress:(NSData *)addr inputStream:(NSInputStream *)istr outputStream:(NSOutputStream *)ostr;
- (void)broadcast:(uint8_t *)buffer size:(unsigned int)size;
@end
