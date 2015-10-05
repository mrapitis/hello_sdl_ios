//
//  FMCProxyManager.m
//  HelloSDL
//
//  Created by Ford Developer on 10/5/15.
//  Copyright © 2015 Ford. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMCProxyManager.h"
#import <SmartDeviceLink.h>


@interface FMCProxyManager () <SDLProxyListener>
@end

@implementation FMCProxyManager


#pragma mark Lifecycle

// Singleton method
+ (instancetype)manager {
    static FMCProxyManager *proxyManager = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        proxyManager = [[self alloc] init];
    });
    
    return proxyManager;
}

- (instancetype)init {
    if (self = [super init]) {
    }
    return self;
}


#pragma mark FMCProxyManager


#pragma mark SDLProxyListener

- (void)onProxyOpened {
    // Delegate method that occurs on connect (but not registered) with SYNC
    [SDLDebugTool logInfo:@"SYNC Connect"];
}

- (void)onProxyClosed {
    // Delegate method that occurs on disconnect from SYNC
    [SDLDebugTool logInfo:@"SYNC Disconnect"];
}

- (void)onOnDriverDistraction:(SDLOnDriverDistraction *)notification {
    
}

- (void)onOnHMIStatus:(SDLOnHMIStatus *)notification {
    
}

- (void)onRegisterAppInterfaceResponse:(SDLRegisterAppInterfaceResponse *)response {
    // Delegate method that occurs when the registration response is received from SYNC
    [SDLDebugTool logInfo:@"RegisterAppInterfaceResponse from SYNC"];
}

- (void)onOnLockScreenNotification:(SDLLockScreenStatus *)notification {
    // Delegate method that occurs when lockscreen status changes
    [SDLDebugTool logInfo:@"LockScreen notification from SYNC"];
}

/*
- (void)onAddCommandResponse:(SDLAddCommandResponse *)response;
- (void)onAddSubMenuResponse:(SDLAddSubMenuResponse *)response;
- (void)onAlertManeuverResponse:(SDLAlertManeuverResponse *)request;
- (void)onAlertResponse:(SDLAlertResponse *)response;
- (void)onChangeRegistrationResponse:(SDLChangeRegistrationResponse *)response;
- (void)onCreateInteractionChoiceSetResponse:(SDLCreateInteractionChoiceSetResponse *)response;
- (void)onDeleteCommandResponse:(SDLDeleteCommandResponse *)response;
- (void)onDeleteFileResponse:(SDLDeleteFileResponse *)response;
- (void)onDeleteInteractionChoiceSetResponse:(SDLDeleteInteractionChoiceSetResponse *)response;
- (void)onDeleteSubMenuResponse:(SDLDeleteSubMenuResponse *)response;
- (void)onDiagnosticMessageResponse:(SDLDiagnosticMessageResponse *)response;
- (void)onDialNumberResponse:(SDLDialNumberResponse *)request;
- (void)onEncodedSyncPDataResponse:(SDLEncodedSyncPDataResponse *)response;
- (void)onEndAudioPassThruResponse:(SDLEndAudioPassThruResponse *)response;
- (void)onError:(NSException *)e;
- (void)onGenericResponse:(SDLGenericResponse *)response;
- (void)onGetDTCsResponse:(SDLGetDTCsResponse *)response;
- (void)onGetVehicleDataResponse:(SDLGetVehicleDataResponse *)response;
- (void)onListFilesResponse:(SDLListFilesResponse *)response;
- (void)onReceivedLockScreenIcon:(UIImage *)icon;
- (void)onOnAppInterfaceUnregistered:(SDLOnAppInterfaceUnregistered *)notification;
- (void)onOnAudioPassThru:(SDLOnAudioPassThru *)notification;
- (void)onOnButtonEvent:(SDLOnButtonEvent *)notification;
- (void)onOnButtonPress:(SDLOnButtonPress *)notification;
- (void)onOnCommand:(SDLOnCommand *)notification;
- (void)onOnEncodedSyncPData:(SDLOnEncodedSyncPData *)notification;
- (void)onOnHashChange:(SDLOnHashChange *)notification;
- (void)onOnLanguageChange:(SDLOnLanguageChange *)notification;
- (void)onOnPermissionsChange:(SDLOnPermissionsChange *)notification;
- (void)onOnSyncPData:(SDLOnSyncPData *)notification;
- (void)onOnSystemRequest:(SDLOnSystemRequest *)notification;
- (void)onOnTBTClientState:(SDLOnTBTClientState *)notification;
- (void)onOnTouchEvent:(SDLOnTouchEvent *)notification;
- (void)onOnVehicleData:(SDLOnVehicleData *)notification;
- (void)onPerformAudioPassThruResponse:(SDLPerformAudioPassThruResponse *)response;
- (void)onPerformInteractionResponse:(SDLPerformInteractionResponse *)response;
- (void)onPutFileResponse:(SDLPutFileResponse *)response;
- (void)onReadDIDResponse:(SDLReadDIDResponse *)response;
- (void)onResetGlobalPropertiesResponse:(SDLResetGlobalPropertiesResponse *)response;
- (void)onScrollableMessageResponse:(SDLScrollableMessageResponse *)response;
- (void)onSendLocationResponse:(SDLSendLocationResponse *)request;
- (void)onSetAppIconResponse:(SDLSetAppIconResponse *)response;
- (void)onSetDisplayLayoutResponse:(SDLSetDisplayLayoutResponse *)response;
- (void)onSetGlobalPropertiesResponse:(SDLSetGlobalPropertiesResponse *)response;
- (void)onSetMediaClockTimerResponse:(SDLSetMediaClockTimerResponse *)response;
- (void)onShowConstantTBTResponse:(SDLShowConstantTBTResponse *)response;
- (void)onShowResponse:(SDLShowResponse *)response;
- (void)onSliderResponse:(SDLSliderResponse *)response;
- (void)onSpeakResponse:(SDLSpeakResponse *)response;
- (void)onSubscribeButtonResponse:(SDLSubscribeButtonResponse *)response;
- (void)onSubscribeVehicleDataResponse:(SDLSubscribeVehicleDataResponse *)response;
- (void)onSyncPDataResponse:(SDLSyncPDataResponse *)response;
- (void)onUpdateTurnListResponse:(SDLUpdateTurnListResponse *)response;
- (void)onUnregisterAppInterfaceResponse:(SDLUnregisterAppInterfaceResponse *)response;
- (void)onUnsubscribeButtonResponse:(SDLUnsubscribeButtonResponse *)response;
- (void)onUnsubscribeVehicleDataResponse:(SDLUnsubscribeVehicleDataResponse *)response;
*/

@end
