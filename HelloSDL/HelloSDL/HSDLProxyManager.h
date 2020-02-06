//
//  HSDLProxyManager.h
//  HelloSDL
//
//  Created by Ford Developer on 10/5/15.
//  Copyright © 2015 Ford. All rights reserved.
//

typedef void (^HSDLConnectionResponseHandler)(BOOL _isConnected);

@interface HSDLProxyManager : NSObject

@property (assign, nonatomic) BOOL isConnected;

+ (instancetype)sharedManager;
- (void)startWithResponseHandler:(HSDLConnectionResponseHandler)handler;
- (void)stop;

@end
