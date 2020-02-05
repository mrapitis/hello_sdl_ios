//
//  HSDLProxyManager.h
//  HelloSDL
//
//  Created by Ford Developer on 10/5/15.
//  Copyright © 2015 Ford. All rights reserved.
//


typedef void (^HSDLHMIStatusHandler)(__kindof NSString *hmiStatus);

#import <SmartDeviceLink/SmartDeviceLink.h>

@interface HSDLProxyManager : NSObject

- (instancetype)initWithLifeCycleConfiguration:(SDLLifecycleConfiguration *)lifecycleConfig  withHMIStatusHandler:(HSDLHMIStatusHandler) hmiHandler;
- (void)start;
- (void)stop;

@end
