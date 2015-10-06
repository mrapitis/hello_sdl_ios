//
//  FMCProxyManager.h
//  HelloSDL
//
//  Created by Ford Developer on 10/5/15.
//  Copyright © 2015 Ford. All rights reserved.
//

#ifndef FMCProxyManager_h
#define FMCProxyManager_h

extern NSString *const SDLDisconnectNotification;
extern NSString *const SDLLockScreenStatusNotification;
extern NSString *const SDLNotificationUserInfoObject;

@interface FMCProxyManager : NSObject

+ (instancetype)manager;
- (void)startProxy;
- (void)disposeProxy;

@end

#endif /* FMCProxyManager_h */
