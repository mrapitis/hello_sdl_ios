//
//  HSDLProxyManager.m
//  HelloSDL
//
//  Created by Ford Developer on 10/5/15.
//  Copyright © 2015 Ford. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HSDLProxyManager.h"
@import SmartDeviceLink_iOS;

#warning TODO: Change these to match your app settings!!
// TCP/IP (Emulator) configuration
static NSString *const RemoteIpAddress = @"127.0.0.1";
static NSString *const RemotePort = @"12345";
// App configuration
static NSString *const AppName = @"HelloSDL";
static NSString *const AppId = @"8675309";
static const BOOL AppIsMediaApp = NO;
static NSString *const ShortAppName = @"Hello";
static NSString *const AppVrSynonym = @"Hello S D L";
static NSString *const IconFile = @"sdl_icon.png";
// Welcome message
static NSString *const WelcomeShow = @"Welcome to HelloSDL";
static NSString *const WelcomeSpeak = @"Welcome to Hello S D L";
// Sample AddCommand
static NSString *const TestCommandName = @"Test Command";
static const NSUInteger TestCommandID = 1;

// Notifications used to show/hide lockscreen in the AppDelegate
NSString *const HSDLDisconnectNotification = @"com.sdl.notification.sdldisconnect";
NSString *const HSDLLockScreenStatusNotification = @"com.sdl.notification.sdlchangeLockScreenStatus";
NSString *const HSDLNotificationUserInfoObject = @"com.sdl.notification.keys.sdlnotificationObject";

@interface HSDLProxyManager () <SDLProxyListener>

@property (nonatomic, strong) SDLProxy *proxy;
@property (nonatomic, assign) NSUInteger correlationID;
@property (nonatomic, strong) NSNumber *appIconId;
@property (nonatomic, strong) NSMutableSet *remoteImages;
@property (nonatomic, assign, getter=isConnected) BOOL connected;
@property (nonatomic, assign, getter=isGraphicsSupported) BOOL graphicsSupported;
@property (nonatomic, assign, getter=isFirstHmiFull) BOOL firstHmiFull;
@property (nonatomic, assign, getter=isFirstHmiNotNone) BOOL firstHmiNotNone;
@property (nonatomic, assign, getter=isVehicleDataSubscribed) BOOL vehicleDataSubscribed;

@end

@implementation HSDLProxyManager

#pragma mark Lifecycle

/**
 *  Singleton method.
 */
+ (instancetype)manager {
    static HSDLProxyManager *proxyManager = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
      proxyManager = [[self alloc] init];
    });

    return proxyManager;
}

- (instancetype)init {
    if (self = [super init]) {
        _correlationID = 1;
        _connected = NO;
        _graphicsSupported = NO;
        _firstHmiFull = YES;
        _firstHmiNotNone = YES;
        _remoteImages = [[NSMutableSet alloc] init];
        _vehicleDataSubscribed = NO;
    }
    return self;
}

/**
 *  Posts SDL notifications.
 *
 *  @param name The name of the SDL notification
 *  @param info The data associated with the notification
 */
- (void)hsdl_postNotification:(NSString *)name info:(id)info {
    NSDictionary *userInfo = nil;
    if (info != nil) {
        userInfo = @{
            HSDLNotificationUserInfoObject : info
        };
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:name object:self userInfo:userInfo];
}

#pragma mark Proxy Lifecycle

/**
 *  Start listening for SDL connections.
 */
- (void)startProxy {
    NSLog(@"startProxy");
    self.proxy = [SDLProxyFactory buildSDLProxyWithListener:self tcpIPAddress:RemoteIpAddress tcpPort:RemotePort];
}

/**
 *  Disconnect and destroy the current proxy.
 */
- (void)disposeProxy {
    NSLog(@"disposeProxy");
    [self.proxy dispose];
    self.proxy = nil;
}

/**
 *  Delegate method that runs on SDL connect.
 */
- (void)onProxyOpened {
    NSLog(@"SDL Connect");
    
    self.connected = YES;

    // Build and send RegisterAppInterface request
    SDLRegisterAppInterface *raiRequest = [SDLRPCRequestFactory buildRegisterAppInterfaceWithAppName:AppName languageDesired:[SDLLanguage EN_US] appID:AppId];
    raiRequest.isMediaApplication = @(AppIsMediaApp);
    raiRequest.ngnMediaScreenAppName = ShortAppName;
    raiRequest.vrSynonyms = [NSMutableArray arrayWithObject:AppVrSynonym];
    NSMutableArray *ttsName = [NSMutableArray arrayWithObject:[SDLTTSChunkFactory buildTTSChunkForString:AppName type:SDLSpeechCapabilities.TEXT]];
    raiRequest.ttsName = ttsName;
    [self.proxy sendRPC:raiRequest];
}

- (void)manualDisconnect {
    if (self.isConnected)
        [self onProxyClosed];
}

/**
 *  Delegate method that runs on disconnect from SDL.
 */
- (void)onProxyClosed {
    NSLog(@"SDL Disconnect");

    // Reset state variables
    self.connected = NO;
    self.firstHmiFull = YES;
    self.firstHmiNotNone = YES;
    self.graphicsSupported = NO;
    [self.remoteImages removeAllObjects];
    self.vehicleDataSubscribed = NO;
    self.appIconId = nil;

    // Notify the app delegate to clear the lockscreen
    [self hsdl_postNotification:HSDLDisconnectNotification info:nil];

    // Cycle the proxy
    [self disposeProxy];
}

/**
 *  Delegate method that runs when the registration response is received from SDL.
 */
- (void)onRegisterAppInterfaceResponse:(SDLRegisterAppInterfaceResponse *)response {
    NSLog(@"RegisterAppInterface response from SDL: %@ with info :%@", response.resultCode, response.info);

    if (!response || [response.success isEqual:@0]) {
        NSLog(@"Failed to register with SDL: %@", response);
        return;
    }

    // Check for graphics capability, and upload persistent graphics (app icon) if available
    if (response.displayCapabilities) {
        if (response.displayCapabilities.graphicSupported) {
            self.graphicsSupported = [response.displayCapabilities.graphicSupported boolValue];
        }
    }
    if (self.isGraphicsSupported) {
        [self hsdl_uploadImages];
    }
}

/**
 *  Auto-increment and return the next correlation ID for an RPC.
 *
 *  @return The next correlation ID as an NSNumber.
 */
- (NSNumber *)hsdl_getNextCorrelationId {
    return [NSNumber numberWithUnsignedInteger:++self.correlationID];
}

#pragma mark HMI

/**
 *  Delegate method that runs when the app's HMI state on SDL changes.
 */
- (void)onOnHMIStatus:(SDLOnHMIStatus *)notification {
    NSLog(@"HMIStatus notification from SDL");

    // Send welcome message on first HMI FULL
    if ([[SDLHMILevel FULL] isEqualToEnum:notification.hmiLevel]) {
        if (self.isFirstHmiFull) {
            self.firstHmiFull = NO;
            [self hsdl_performWelcomeMessage];
        }

        // Other HMI (Show, PerformInteraction, etc.) would go here
    }

    // Send AddCommands in first non-HMI NONE state (i.e., FULL, LIMITED, BACKGROUND)
    if (![[SDLHMILevel NONE] isEqualToEnum:notification.hmiLevel]) {
        if (self.isFirstHmiNotNone) {
            self.firstHmiNotNone = NO;
            [self hsdl_addCommands];

            // Other app setup (SubMenu, CreateChoiceSet, etc.) would go here
        }
    }
}

/**
 *  Send welcome message (Speak and Show).
 */
- (void)hsdl_performWelcomeMessage {
    NSLog(@"Send welcome message");
    SDLShow *show = [[SDLShow alloc] init];
    show.mainField1 = WelcomeShow;
    show.alignment = [SDLTextAlignment CENTERED];
    show.correlationID = [self hsdl_getNextCorrelationId];
    [self.proxy sendRPC:show];

    SDLSpeak *speak = [SDLRPCRequestFactory buildSpeakWithTTS:WelcomeSpeak correlationID:[self hsdl_getNextCorrelationId]];
    [self.proxy sendRPC:speak];
}

/**
 *  Delegate method that runs when driver distraction mode changes.
 */
- (void)onOnDriverDistraction:(SDLOnDriverDistraction *)notification {
    NSLog(@"OnDriverDistraction notification from SDL");
    // Some RPCs (depending on region) cannot be sent when driver distraction is active.
}

#pragma mark AppIcon

/**
 *  Requests list of images to SDL, and uploads images that are missing.
 *      Called automatically by the onRegisterAppInterfaceResponse method.
 *      Note: Don't need to check for graphics support here; it is checked by the caller.
 */
- (void)hsdl_uploadImages {
    NSLog(@"hsdl_uploadImages");
    [self.remoteImages removeAllObjects];

    // Perform a ListFiles RPC to check which files are already present on SDL
    SDLListFiles *list = [[SDLListFiles alloc] init];
    list.correlationID = [self hsdl_getNextCorrelationId];
    [self.proxy sendRPC:list];
}

/**
 *  Delegate method that runs when the list files response is received from SDL.
 */
- (void)onListFilesResponse:(SDLListFilesResponse *)response {
    NSLog(@"ListFiles response from SDL: %@ with info: %@", response.resultCode, response.info);

    // If the ListFiles was successful, store the list in a mutable set
    if (response.success) {
        for (NSString *filename in response.filenames) {
            [self.remoteImages addObject:filename];
        }
    }

    // Check the mutable set for the AppIcon
    // If not present, upload the image
    if (![self.remoteImages containsObject:IconFile]) {
        self.appIconId = [self hsdl_getNextCorrelationId];
        [self hsdl_uploadImage:IconFile withCorrelationID:self.appIconId];
    } else {
        // If the file is already present, send the SetAppIcon request
        [self hsdl_setAppIcon];
    }

    // Other images (for Show, etc.) could be added here
}

/**
 *  Upload a persistent PNG image to SDL.
 *      The correlation ID can be used in the onPutFileResponse delegate method
 *      to determine when the upload is complete.
 *
 *  @param imageName The name of the image in the Assets catalog.
 *  @param corrId    The correlation ID used in the request.
 */
- (void)hsdl_uploadImage:(NSString *)imageName withCorrelationID:(NSNumber *)corrId {
    NSLog(@"hsdl_uploadImage: %@", imageName);
    if (imageName) {
        UIImage *pngImage = [UIImage imageNamed:IconFile];
        if (pngImage) {
            NSData *pngData = UIImagePNGRepresentation(pngImage);
            if (pngData) {
                SDLPutFile *putFile = [[SDLPutFile alloc] init];
                putFile.syncFileName = imageName;
                putFile.fileType = [SDLFileType GRAPHIC_PNG];
                putFile.persistentFile = @YES;
                putFile.systemFile = @NO;
                putFile.offset = @0;
                putFile.length = [NSNumber numberWithUnsignedLong:pngData.length];
                putFile.bulkData = pngData;
                putFile.correlationID = corrId;
                [self.proxy sendRPC:putFile];
            }
        }
    }
}

/**
 *  Delegate method that runs when a PutFile is complete.
 */
- (void)onPutFileResponse:(SDLPutFileResponse *)response {
    NSLog(@"PutFile response from SDL: %@ with info: %@", response.resultCode, response.info);

    // On success and matching app icon correlation ID, send a SetAppIcon request
    if (response.success && [response.correlationID isEqual:self.appIconId]) {
        [self hsdl_setAppIcon];
    }
}

/**
 *  Send the SetAppIcon request to SDL.
 *      Called automatically in the OnPutFileResponse method.
 */
- (void)hsdl_setAppIcon {
    NSLog(@"hsdl_setAppIcon");
    SDLSetAppIcon *setIcon = [[SDLSetAppIcon alloc] init];
    setIcon.syncFileName = IconFile;
    setIcon.correlationID = [self hsdl_getNextCorrelationId];
    [self.proxy sendRPC:setIcon];
}

#pragma mark Lockscreen

/**
 *  Delegate method that runs when lockscreen status changes.
 */
- (void)onOnLockScreenNotification:(SDLLockScreenStatus *)notification {
    NSLog(@"OnLockScreen notification from SDL");

    // Notify the app delegate
    [self hsdl_postNotification:HSDLLockScreenStatusNotification info:notification];
}

#pragma mark Commands

/**
 *  Add commands for the app on SDL.
 */
- (void)hsdl_addCommands {
    NSLog(@"hsdl_addCommands");
    SDLMenuParams *menuParams = [[SDLMenuParams alloc] init];
    menuParams.menuName = TestCommandName;
    SDLAddCommand *command = [[SDLAddCommand alloc] init];
    command.vrCommands = [NSMutableArray arrayWithObject:TestCommandName];
    command.menuParams = menuParams;
    command.cmdID = @(TestCommandID);
    [self.proxy sendRPC:command];
}

/**
 *  Delegate method that runs when the add command response is received from SDL.
 */
- (void)onAddCommandResponse:(SDLAddCommandResponse *)response {
    NSLog(@"AddCommand response from SDL: %@ with info: %@", response.resultCode, response.info);
}

/**
 *  Delegate method that runs when a command is triggered on SDL.
 */
- (void)onOnCommand:(SDLOnCommand *)notification {
    NSLog(@"OnCommand notification from SDL");

    // Handle sample command when triggered
    if ([notification.cmdID isEqual:@(TestCommandID)]) {
        SDLShow *show = [[SDLShow alloc] init];
        show.mainField1 = @"Test Command";
        show.alignment = [SDLTextAlignment CENTERED];
        show.correlationID = [self hsdl_getNextCorrelationId];
        [self.proxy sendRPC:show];

        SDLSpeak *speak = [SDLRPCRequestFactory buildSpeakWithTTS:@"Test Command" correlationID:[self hsdl_getNextCorrelationId]];
        [self.proxy sendRPC:speak];
    }
}

#pragma mark VehicleData

// TODO: uncomment the methods below for vehicle data

/**
 *  Delegate method that runs when the app's permissions change on SDL.
 */
/*- (void)onOnPermissionsChange:(SDLOnPermissionsChange *)notification {
    NSLog(@"OnPermissionsChange notification from SDL");

    // Check for permission to subscribe to vehicle data before sending the request
    NSMutableArray *permissionArray = notification.permissionItem;
    for (SDLPermissionItem *item in permissionArray) {
        if ([item.rpcName isEqualToString:@"SubscribeVehicleData"]) {
            if (item.hmiPermissions.allowed && item.hmiPermissions.allowed.count > 0) {
                [self hsdl_subscribeVehicleData];
            }
        }
    }
}*/

/**
 *  Subscribe to (periodic) vehicle data updates from SDL.
 */
/*- (void)hsdl_subscribeVehicleData {
    NSLog(@"hsdl_subscribeVehicleData");
    if (!self.isVehicleDataSubscribed) {
        SDLSubscribeVehicleData *subscribe = [[SDLSubscribeVehicleData alloc] init];
        subscribe.correlationID = [self hsdl_getNextCorrelationId];

#warning TODO: Add the vehicle data items you want to subscribe to
        // Specify which items to subscribe to
        subscribe.speed = @YES;

        [self.proxy sendRPC:subscribe];
    }
}*/

/**
 *  Delegate method that runs when the subscribe vehicle data response is received from SDL.
 */
/*- (void)onSubscribeVehicleDataResponse:(SDLSubscribeVehicleDataResponse *)response {
    NSLog(@"SubscribeVehicleData response from SDL: %@ with info: %@", response.resultCode, response.info);

    if (response && [[SDLResult SUCCESS] isEqualToEnum:response.resultCode]) {
        NSLog(@"Vehicle data subscribed!");
        self.vehicleDataSubscribed = YES;
    }
}*/

/**
 *  Delegate method that runs when new vehicle data is received from SDL.
 */
/*- (void)onOnVehicleData:(SDLOnVehicleData *)notification {
    NSLog(@"OnVehicleData notification from SDL");

#warning TODO: Put your vehicle data code here!
    NSLog(@"Speed: %@", notification.speed);
}*/

/*
 
 */


#pragma mark Notification callbacks

- (void)onOnAppInterfaceUnregistered:(SDLOnAppInterfaceUnregistered *)notification {
    NSLog(@"onAppInterfaceUnregistered notification from SDL");
}

- (void)onOnAudioPassThru:(SDLOnAudioPassThru *)notification {
    NSLog(@"onAudioPassThru notification from SDL");
}

- (void)onOnButtonEvent:(SDLOnButtonEvent *)notification {
    NSLog(@"onButtonEvent notification from SDL");
}

- (void)onOnButtonPress:(SDLOnButtonPress *)notification {
    NSLog(@"onButtonPress notification from SDL");
}

- (void)onOnEncodedSyncPData:(SDLOnEncodedSyncPData *)notification {
    NSLog(@"onEncodedSyncPData from SDL");
}

- (void)onOnHashChange:(SDLOnHashChange *)notification {
    NSLog(@"onHashChange notification from SDL");
}

- (void)onOnLanguageChange:(SDLOnLanguageChange *)notification {
    NSLog(@"onLanguageChange notification from SDL");
}

- (void)onOnSyncPData:(SDLOnSyncPData *)notification {
    NSLog(@"onSyncPData notification from SDL");
}

- (void)onOnSystemRequest:(SDLOnSystemRequest *)notification {
    NSLog(@"onSystemRequest notification from SDL");
}

- (void)onOnTBTClientState:(SDLOnTBTClientState *)notification {
    NSLog(@"onTBTClientState notification from SDL");
}

- (void)onOnTouchEvent:(SDLOnTouchEvent *)notification {
    NSLog(@"onTouchEvent notification from SDL");
}


#pragma mark Other callbacks

- (void)onAddSubMenuResponse:(SDLAddSubMenuResponse *)response {
    NSLog(@"AddSubMenu response from SDL with result code: %@ and info: %@", response.resultCode, response.info);
}

- (void)onAlertManeuverResponse:(SDLAlertManeuverResponse *)request {
    NSLog(@"AlertManeuver response from SDL with result code: %@ and info: %@", request.resultCode, request.info);
}

- (void)onAlertResponse:(SDLAlertResponse *)response {
    NSLog(@"Alert response from SDL with result code: %@ and info: %@", response.resultCode, response.info);
}

- (void)onChangeRegistrationResponse:(SDLChangeRegistrationResponse *)response {
    NSLog(@"ChangeRegistration response from SDL with result code: %@ and info: %@", response.resultCode, response.info);
}

- (void)onCreateInteractionChoiceSetResponse:(SDLCreateInteractionChoiceSetResponse *)response {
    NSLog(@"CreateInteractionChoiceSet response from SDL with result code: %@ and info: %@", response.resultCode, response.info);
}

- (void)onDeleteCommandResponse:(SDLDeleteCommandResponse *)response {
    NSLog(@"DeleteCommand response from SDL with result code: %@ and info: %@", response.resultCode, response.info);
}

- (void)onDeleteFileResponse:(SDLDeleteFileResponse *)response {
    NSLog(@"DeleteFile response from SDL with result code: %@ and info: %@", response.resultCode, response.info);
}

- (void)onDeleteInteractionChoiceSetResponse:(SDLDeleteInteractionChoiceSetResponse *)response {
    NSLog(@"DeleteInteractionChoiceSet response from SDL with result code: %@ and info: %@", response.resultCode, response.info);
}

- (void)onDeleteSubMenuResponse:(SDLDeleteSubMenuResponse *)response {
    NSLog(@"DeleteSubMenu response from SDL with result code: %@ and info: %@", response.resultCode, response.info);
}

- (void)onDiagnosticMessageResponse:(SDLDiagnosticMessageResponse *)response {
    NSLog(@"DiagnosticMessage response from SDL with result code: %@ and info: %@", response.resultCode, response.info);
}

- (void)onDialNumberResponse:(SDLDialNumberResponse *)request {
    NSLog(@"DialNumber response from SDL with result code: %@ and info: %@", request.resultCode, request.info);
}

- (void)onEncodedSyncPDataResponse:(SDLEncodedSyncPDataResponse *)response {
    NSLog(@"EncodedSyncPData response from SDL with result code: %@ and info: %@", response.resultCode, response.info);
}

- (void)onEndAudioPassThruResponse:(SDLEndAudioPassThruResponse *)response {
    NSLog(@"EndAudioPassThru response from SDL with result code: %@ and info: %@", response.resultCode, response.info);
}

- (void)onError:(NSException *)e {
    NSLog(@"Error response from SDL with name: %@ and reason: %@", e.name, e.reason);
}

- (void)onGenericResponse:(SDLGenericResponse *)response {
    NSLog(@"Generic response from SDL with result code: %@ and info: %@", response.resultCode, response.info);
}

- (void)onGetDTCsResponse:(SDLGetDTCsResponse *)response {
    NSLog(@"GetDTCs response from SDL with result code: %@ and info: %@", response.resultCode, response.info);
}

- (void)onGetVehicleDataResponse:(SDLGetVehicleDataResponse *)response {
    NSLog(@"GetVehicleData response from SDL with result code: %@ and info: %@", response.resultCode, response.info);
}

- (void)onReceivedLockScreenIcon:(UIImage *)icon {
    NSLog(@"ReceivedLockScreenIcon notification from SDL");
}

- (void)onPerformAudioPassThruResponse:(SDLPerformAudioPassThruResponse *)response {
    NSLog(@"PerformAudioPassThru response from SDL with result code: %@ and info: %@", response.resultCode, response.info);
}

- (void)onPerformInteractionResponse:(SDLPerformInteractionResponse *)response {
    NSLog(@"PerformInteraction response from SDL with result code: %@ and info: %@", response.resultCode, response.info);
}

- (void)onReadDIDResponse:(SDLReadDIDResponse *)response {
    NSLog(@"ReadDID response from SDL with result code: %@ and info: %@", response.resultCode, response.info);
}

- (void)onResetGlobalPropertiesResponse:(SDLResetGlobalPropertiesResponse *)response {
    NSLog(@"ResetGlobalProperties response from SDL with result code: %@ and info: %@", response.resultCode, response.info);
}

- (void)onScrollableMessageResponse:(SDLScrollableMessageResponse *)response {
    NSLog(@"ScrollableMessage response from SDL with result code: %@ and info: %@", response.resultCode, response.info);
}

- (void)onSendLocationResponse:(SDLSendLocationResponse *)request {
    NSLog(@"SendLocation response from SDL with result code: %@ and info: %@", request.resultCode, request.info);
}

- (void)onSetAppIconResponse:(SDLSetAppIconResponse *)response {
    NSLog(@"SetAppIcon response from SDL with result code: %@ and info: %@", response.resultCode, response.info);
}

- (void)onSetDisplayLayoutResponse:(SDLSetDisplayLayoutResponse *)response {
    NSLog(@"SetDisplayLayout response from SDL with result code: %@ and info: %@", response.resultCode, response.info);
}

- (void)onSetGlobalPropertiesResponse:(SDLSetGlobalPropertiesResponse *)response {
    NSLog(@"SetGlobalProperties response from SDL with result code: %@ and info: %@", response.resultCode, response.info);
}

- (void)onSetMediaClockTimerResponse:(SDLSetMediaClockTimerResponse *)response {
    NSLog(@"SetMediaClockTimer response from SDL with result code: %@ and info: %@", response.resultCode, response.info);
}

- (void)onShowConstantTBTResponse:(SDLShowConstantTBTResponse *)response {
    NSLog(@"ShowConstantTBT response from SDL with result code: %@ and info: %@", response.resultCode, response.info);
}

- (void)onShowResponse:(SDLShowResponse *)response {
    NSLog(@"Show response from SDL with result code: %@ and info: %@", response.resultCode, response.info);
}

- (void)onSliderResponse:(SDLSliderResponse *)response {
    NSLog(@"Slider response from SDL with result code: %@ and info: %@", response.resultCode, response.info);
}

- (void)onSpeakResponse:(SDLSpeakResponse *)response {
    NSLog(@"Speak response from SDL with result code: %@ and info: %@", response.resultCode, response.info);
}

- (void)onSubscribeButtonResponse:(SDLSubscribeButtonResponse *)response {
    NSLog(@"SubscribeButton response from SDL with result code: %@ and info: %@", response.resultCode, response.info);
}

- (void)onSyncPDataResponse:(SDLSyncPDataResponse *)response {
    NSLog(@"SyncPData response from SDL with result code: %@ and info: %@", response.resultCode, response.info);
}

- (void)onUpdateTurnListResponse:(SDLUpdateTurnListResponse *)response {
    NSLog(@"UpdateTurnList response from SDL with result code: %@ and info: %@", response.resultCode, response.info);
}

- (void)onUnregisterAppInterfaceResponse:(SDLUnregisterAppInterfaceResponse *)response {
    NSLog(@"UnregisterAppInterface response from SDL with result code: %@ and info: %@", response.resultCode, response.info);
}

- (void)onUnsubscribeButtonResponse:(SDLUnsubscribeButtonResponse *)response {
    NSLog(@"UnsubscribeButton response from SDL with result code: %@ and info: %@", response.resultCode, response.info);
}

- (void)onUnsubscribeVehicleDataResponse:(SDLUnsubscribeVehicleDataResponse *)response {
    NSLog(@"UnsubscribeVehicleData response from SDL with result code: %@ and info: %@", response.resultCode, response.info);
}

@end
