#import <Foundation/Foundation.h>

#if !TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#import <CoreServices/CoreServices.h>
#else
#import <CFNetwork/CFNetwork.h>
#endif

NSString * const TCPServerErrorDomain;

typedef enum {
    kTCPServerCouldNotBindToIPv4Address = 1,
    kTCPServerNoSocketsAvailable = 2,
} TCPServerErrorCode;

@interface TCPServer : NSObject {
@private
    id delegate;
    NSString *domain;
    NSString *name;
    NSString *type;
    uint16_t port;
    CFSocketRef ipv4socket;
    NSNetService *netService;
}

- (id)delegate;
- (void)setDelegate:(id)value;

- (NSString *)domain;
- (void)setDomain:(NSString *)value;

- (NSString *)name;
- (void)setName:(NSString *)value;

- (NSString *)type;
- (void)setType:(NSString *)value;

- (uint16_t)port;
- (void)setPort:(uint16_t)value;

- (BOOL)start:(NSError **)error;
- (BOOL)stop;

/**
 * Called when a new connection comes in; by default, informs the delegate
 */
- (void)handleNewConnectionFromAddress:(NSData *)addr inputStream:(NSInputStream *)istr outputStream:(NSOutputStream *)ostr;

@end

@interface TCPServer (TCPServerDelegateMethods)
/**
 * If the delegate implements this method, it is called when a new  
 * connection comes in; a subclass may, of course, change that behavior
 */
- (void)TCPServer:(TCPServer *)server didReceiveConnectionFromAddress:(NSData *)addr inputStream:(NSInputStream *)istr outputStream:(NSOutputStream *)ostr;
@end
