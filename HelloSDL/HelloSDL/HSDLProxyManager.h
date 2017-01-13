//
//  HSDLProxyManager.h
//  HelloSDL
//
//

#import <SmartDeviceLink/SmartDeviceLink.h>

@interface HSDLProxyManager : NSObject

@property (strong, nonatomic) NSMutableArray *finalVehicleDataArray;
@property (nonatomic, strong) NSMutableDictionary *requestBuffer;

+ (instancetype)manager;
- (void)startProxy;
- (void)disposeProxy;
- (NSNumber *)hsdl_getNextCorrelationId;
- (void)sendAndPostRPCMessage:(SDLRPCRequest *)rpcMsg;
- (void)postToConsoleLog:(id)object;


@end
