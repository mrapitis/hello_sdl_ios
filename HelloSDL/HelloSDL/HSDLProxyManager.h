//
//  HSDLProxyManager.h
//  HelloSDL
//
//  Created by Ford Developer on 10/5/15.
//  Copyright © 2015 Ford. All rights reserved.
//

@interface HSDLProxyManager : NSObject

+ (instancetype)sharedManager;
- (void)start;
- (void)stop;

@end
