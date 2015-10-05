//
//  FMCVehicleDataManager.m
//  HelloSDL
//
//  Created by Ford Developer on 10/5/15.
//  Copyright © 2015 Ford. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMCVehicleDataManager.h"
#import <SmartDeviceLink.h>

@interface FMCVehicleDataManager ()
@property (nonatomic, assign) BOOL vehicleDataSubscribed;
@end

@implementation FMCVehicleDataManager

#pragma mark Lifecycle

- (instancetype)init {
    if (self = [super init]) {
        _vehicleDataSubscribed = NO;
        [self registerForSDLNotifications];
    }
    return self;
}


#pragma mark FMCVehicleDataManager

- (void)subscribeVehicleData {
    // Subscribe to vehicle data updates from SYNC
    [SDLDebugTool logInfo:@"subscribeVehicleData"];
    if (!self.vehicleDataSubscribed) {
        SDLSubscribeVehicleData *subscribe = [[SDLSubscribeVehicleData alloc] init];
        
        // TODO: specify which vehicle data items you want to subscribe to!!
        subscribe.speed = @YES;
        subscribe.rpm = @YES;
        
        __weak typeof(self) weakSelf = self;
        [[SDLManager sharedManager] sendRequest:subscribe withCompletionHandler:^(SDLRPCRequest *request, SDLRPCResponse *response, NSError *error) {
            typeof(self) strongSelf = weakSelf;
            if (response && [[SDLResult SUCCESS] isEqualToEnum:response.resultCode]) {
                if (strongSelf) {
                    [SDLDebugTool logInfo:@"Vehicle data subscribed!"];
                    strongSelf.vehicleDataSubscribed = YES;
                }
            }
        }];
    }
}

- (void)registerForSDLNotifications {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    [center addObserver:self selector:@selector(didChangePermissions:) name:SDLDidChangePermissionsNotification object:nil];
    [center addObserver:self selector:@selector(didDisconnect:) name:SDLDidDisconnectNotification object:nil];
    [center addObserver:self selector:@selector(didReceiveVehicleData:) name:SDLDidReceiveVehicleDataNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark SDL Notifications

- (void)didChangePermissions:(NSNotification *)notification {
    // Notification method to handle permission change notifications from SYNC
    SDLOnPermissionsChange *permissions = nil;
    if (notification && notification.userInfo) {
        permissions = notification.userInfo[SDLNotificationUserInfoNotificationObject];
    }
    
    // Check for permission to subscribe to vehicle data before sending the request
    NSMutableArray *permissionArray = permissions.permissionItem;
    for (SDLPermissionItem *item in permissionArray) {
        if ([item.rpcName isEqualToString:@"SubscribeVehicleData"]) {
            if (item.hmiPermissions.allowed && item.hmiPermissions.allowed.count > 0) {
                [self subscribeVehicleData];
            }
        }
    }
}

- (void)didDisconnect:(NSNotification *)notification {
    // Notification method to perform actions on disconnect from SYNC
    // Cleanup state variables
    self.vehicleDataSubscribed = NO;
}

- (void)didReceiveVehicleData:(NSNotification *)notification {
    // Notification method that receives periodic vehicle data from SYNC
    SDLOnVehicleData *data = nil;
    if (notification && notification.userInfo) {
        data = notification.userInfo[SDLNotificationUserInfoNotificationObject];
    }
    
    // TODO: Put your vehicle data code here!
    if (data) {
        [SDLDebugTool logInfo:[NSString stringWithFormat:@"Speed: %@, RPM: %@",data.speed, data.rpm]];
    }
}

@end
