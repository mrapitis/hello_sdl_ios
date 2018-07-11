//
//  HSDLProxyManager.h
//  HelloSDL
//
//  Created by Ford Developer on 10/5/15.
//  Copyright © 2015 Ford. All rights reserved.
//
@import SmartDeviceLink_iOS;

@interface HSDLProxyManager : NSObject

@property (nonatomic, strong) SDLManager *manager;
+ (instancetype)sharedManager;
- (void)start;
- (void)stop;

@end
