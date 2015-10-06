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


static NSString *const kAppName = @"HelloSDL";
static NSString *const kAppId = @"8675309";
static const BOOL kAppIsMediaApp = NO;
static NSString *const kShortAppName = @"Hello";
static NSString *const kIconFile = @"sdl_icon.png";

static NSString *const kWelcomeShow = @"Welcome to HelloSDL";
static NSString *const kWelcomeSpeak = @"Welcome to Hello S D L";

static NSString *const kTestCommandName = @"Test Command";
static const NSUInteger kTestCommandID = 1;


NSString *const SDLDisconnectNotification = @"com.sdl.notification.disconnect";
NSString *const SDLLockScreenStatusNotification = @"com.sdl.notification.changeLockScreenStatus";
NSString *const SDLNotificationUserInfoObject = @"com.sdl.notification.keys.notificationObject";


@interface FMCProxyManager () <SDLProxyListener>

@property (nonatomic, strong) SDLProxy *proxy;
@property (nonatomic, assign) NSUInteger correlationID;
@property (nonatomic, assign) BOOL graphics;
@property (nonatomic, strong) NSNumber *appIconId;
@property (nonatomic, assign) BOOL firstHmiFull;
@property (nonatomic, assign) BOOL firstHmiNotNone;
@property (nonatomic, strong) NSMutableSet *remoteImages;
@property (nonatomic, assign) BOOL vehicleDataSubscribed;

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
        _correlationID = 1;
        _graphics = NO;
        _firstHmiFull = YES;
        _firstHmiNotNone = YES;
        _remoteImages = [[NSMutableSet alloc] init];
        _vehicleDataSubscribed = NO;
    }
    return self;
}

- (void)postNotification:(NSString *)name info:(id)info {
    NSDictionary *userInfo = nil;
    if (info != nil) {
        userInfo = @{
            SDLNotificationUserInfoObject : info
        };
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:name object:self userInfo:userInfo];
}


#pragma mark Proxy Lifecycle

- (void)startProxy {
    [SDLDebugTool logInfo:@"startProxy"];
    self.proxy = [SDLProxyFactory buildSDLProxyWithListener:self];
}

- (void)disposeProxy {
    [SDLDebugTool logInfo:@"disposeProxy"];
    [self.proxy dispose];
    self.proxy = nil;
}

- (void)onProxyOpened {
    // Delegate method that occurs on connect (but not registered) with SDL
    [SDLDebugTool logInfo:@"SDL Connect"];

    // Build and send RegisterAppInterface request
    SDLRegisterAppInterface *raiRequest = [SDLRPCRequestFactory buildRegisterAppInterfaceWithAppName:kAppName languageDesired:[SDLLanguage EN_US] appID:kAppId];
    raiRequest.isMediaApplication = @(kAppIsMediaApp);
    raiRequest.ngnMediaScreenAppName = kShortAppName;
    raiRequest.vrSynonyms = nil;
    NSMutableArray *ttsName = [NSMutableArray arrayWithObject:[SDLTTSChunkFactory buildTTSChunkForString:kAppName type:SDLSpeechCapabilities.TEXT]];
    raiRequest.ttsName = ttsName;
    [self.proxy sendRPC:raiRequest];
}

- (void)onProxyClosed {
    // Delegate method that occurs on disconnect from SDL
    [SDLDebugTool logInfo:@"SDL Disconnect"];

    // Reset state variables
    self.firstHmiFull = YES;
    self.firstHmiNotNone = YES;
    self.graphics = NO;
    [self.remoteImages removeAllObjects];
    self.vehicleDataSubscribed = NO;
    self.appIconId = nil;

    [self postNotification:SDLDisconnectNotification info:nil];

    // Cycle the proxy
    [self disposeProxy];
    [self startProxy];
}

- (void)onRegisterAppInterfaceResponse:(SDLRegisterAppInterfaceResponse *)response {
    // Delegate method that occurs when the registration response is received from SDL
    [SDLDebugTool logInfo:@"RegisterAppInterface response from SDL"];

    if (!response || [response.success isEqual:@0]) {
        [SDLDebugTool logInfo:[NSString stringWithFormat:@"Failed to register with SDL: %@", response]];
        return;
    }

    // Check for graphics capability, and upload persistent graphics (app icon) if available
    if (response.displayCapabilities) {
        if (response.displayCapabilities.graphicSupported) {
            self.graphics = [response.displayCapabilities.graphicSupported boolValue];
        }
    }
    if (self.graphics) {
        [self uploadImages];
    }
}

- (NSNumber *)getNextCorrelationId {
    self.correlationID++;
    return [NSNumber numberWithUnsignedInteger:self.correlationID];
}


#pragma mark HMI

- (void)onOnHMIStatus:(SDLOnHMIStatus *)notification {
    [SDLDebugTool logInfo:@"HMIStatus notification from SDL"];

    // Send welcome message on first HMI FULL
    if ([[SDLHMILevel FULL] isEqualToEnum:notification.hmiLevel]) {
        if (self.firstHmiFull) {
            self.firstHmiFull = NO;
            [self performWelcomeMessage];
        }
    }

    // Send AddCommands in first non-HMI NONE state (i.e., FULL, LIMITED, BACKGROUND)
    if (![[SDLHMILevel NONE] isEqualToEnum:notification.hmiLevel]) {
        if (self.firstHmiNotNone) {
            self.firstHmiNotNone = NO;
            [self addCommands];
        }
    }
}

- (void)performWelcomeMessage {
    // Send welcome message (Speak and Show)
    [SDLDebugTool logInfo:@"Send welcome message"];
    SDLShow *show = [[SDLShow alloc] init];
    show.mainField1 = kWelcomeShow;
    show.alignment = [SDLTextAlignment CENTERED];
    show.correlationID = [self getNextCorrelationId];
    [self.proxy sendRPC:show];

    SDLSpeak *speak = [SDLRPCRequestFactory buildSpeakWithTTS:kWelcomeSpeak correlationID:[self getNextCorrelationId]];
    [self.proxy sendRPC:speak];
}

- (void)onOnDriverDistraction:(SDLOnDriverDistraction *)notification {
}


#pragma mark AppIcon

- (void)uploadImages {
    // Uploads images to SDL
    // Called automatically by the onRegisterAppInterfaceResponse method
    // Note: Don't need to check for graphics support here; it is checked by the caller
    [SDLDebugTool logInfo:@"uploadImages"];
    [self.remoteImages removeAllObjects];

    // Perform a ListFiles RPC to check which files are already present on SDL
    SDLListFiles *list = [[SDLListFiles alloc] init];
    list.correlationID = [self getNextCorrelationId];
    [self.proxy sendRPC:list];
}

- (void)onListFilesResponse:(SDLListFilesResponse *)response {
    [SDLDebugTool logInfo:@"ListFiles response from SDL"];

    // If the ListFiles was successful, store the list in a mutable array
    if (response.success) {
        for (NSString *filename in response.filenames) {
            [self.remoteImages addObject:filename];
        }
    }

    // Check the mutable array for the AppIcon
    // If not present, upload the image
    if (![self.remoteImages containsObject:kIconFile]) {
        self.appIconId = [self getNextCorrelationId];
        [self uploadImage:kIconFile withCorrelationID:self.appIconId];
    }
    // If the file is already present, send the SetAppIcon request
    else {
        [self setAppIcon];
    }
}

- (void)uploadImage:(NSString *)imageName withCorrelationID:(NSNumber *)corrId {
    // Upload an image from the App's Assets with the specified name
    // Note: Assumes a PNG image type, and persistent storage!!
    [SDLDebugTool logInfo:[NSString stringWithFormat:@"uploadImage: %@", imageName]];
    if (imageName) {
        UIImage *pngImage = [UIImage imageNamed:kIconFile];
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

- (void)onPutFileResponse:(SDLPutFileResponse *)response {
    [SDLDebugTool logInfo:@"PutFile response from SDL"];
    // On success and matching correlation ID, send a SetAppIcon request
    if (response.success && [response.correlationID isEqual:self.appIconId]) {
        [self setAppIcon];
    }
}

- (void)setAppIcon {
    // Sends the SetAppIcon RPC with the image name uploaded via uploadImages
    // Called automatically in the OnPutFileResponse method
    [SDLDebugTool logInfo:@"setAppIcon"];
    SDLSetAppIcon *setIcon = [[SDLSetAppIcon alloc] init];
    setIcon.syncFileName = kIconFile;
    setIcon.correlationID = [self getNextCorrelationId];
    [self.proxy sendRPC:setIcon];
}


#pragma mark Lockscreen

- (void)onOnLockScreenNotification:(SDLLockScreenStatus *)notification {
    // Delegate method that occurs when lockscreen status changes
    [SDLDebugTool logInfo:@"OnLockScreen notification from SDL"];
    [self postNotification:SDLLockScreenStatusNotification info:notification];
}


#pragma mark Commands

- (void)addCommands {
    [SDLDebugTool logInfo:@"addCommands"];
    // Create and send AddCommand
    SDLAddCommand *command = nil;
    SDLMenuParams *menuParams = nil;
    command = [[SDLAddCommand alloc] init];
    menuParams = [[SDLMenuParams alloc] init];
    command.vrCommands = [NSMutableArray arrayWithObject:kTestCommandName];
    menuParams.menuName = kTestCommandName;
    command.menuParams = menuParams;
    command.cmdID = @(kTestCommandID);
    [self.proxy sendRPC:command];
}

- (void)onAddCommandResponse:(SDLAddCommandResponse *)response {
    [SDLDebugTool logInfo:[NSString stringWithFormat:@"AddCommand response from SDL: %@", response]];
}

- (void)onOnCommand:(SDLOnCommand *)notification {
    [SDLDebugTool logInfo:@"OnCommand notification from SDL"];

    // Handle command when triggered
    if ([notification.cmdID isEqual:@(kTestCommandID)]) {
        SDLShow *show = [[SDLShow alloc] init];
        show.mainField1 = @"Test Command";
        show.alignment = [SDLTextAlignment CENTERED];
        show.correlationID = [self getNextCorrelationId];
        [self.proxy sendRPC:show];

        SDLSpeak *speak = [SDLRPCRequestFactory buildSpeakWithTTS:@"Test Command" correlationID:[self getNextCorrelationId]];
        [self.proxy sendRPC:speak];
    }
}


#pragma mark VehicleData

- (void)onOnPermissionsChange:(SDLOnPermissionsChange *)notification {
    [SDLDebugTool logInfo:@"OnPermissionsChange notification from SDL"];
    // Check for permission to subscribe to vehicle data before sending the request
    NSMutableArray *permissionArray = notification.permissionItem;
    for (SDLPermissionItem *item in permissionArray) {
        if ([item.rpcName isEqualToString:@"SubscribeVehicleData"]) {
            if (item.hmiPermissions.allowed && item.hmiPermissions.allowed.count > 0) {
                [self subscribeVehicleData];
            }
        }
    }
}

- (void)subscribeVehicleData {
    // Subscribe to vehicle data updates from SDL
    [SDLDebugTool logInfo:@"subscribeVehicleData"];
    if (!self.vehicleDataSubscribed) {
        SDLSubscribeVehicleData *subscribe = [[SDLSubscribeVehicleData alloc] init];
        subscribe.correlationID = [self getNextCorrelationId];

        subscribe.speed = @YES;

        [self.proxy sendRPC:subscribe];
    }
}

- (void)onSubscribeVehicleDataResponse:(SDLSubscribeVehicleDataResponse *)response {
    [SDLDebugTool logInfo:@"SubscribeVehicleData response from SDL"];
    if (response && [[SDLResult SUCCESS] isEqualToEnum:response.resultCode]) {
        [SDLDebugTool logInfo:@"Vehicle data subscribed!"];
        self.vehicleDataSubscribed = YES;
    }
}

- (void)onOnVehicleData:(SDLOnVehicleData *)notification {
    [SDLDebugTool logInfo:@"OnVehicleData notification from SDL"];
    // TODO: Put your vehicle data code here!
    [SDLDebugTool logInfo:[NSString stringWithFormat:@"Speed: %@", notification.speed]];
}


/*
- (void)onOnAppInterfaceUnregistered:(SDLOnAppInterfaceUnregistered *)notification;
- (void)onOnAudioPassThru:(SDLOnAudioPassThru *)notification;
- (void)onOnButtonEvent:(SDLOnButtonEvent *)notification;
- (void)onOnButtonPress:(SDLOnButtonPress *)notification;
- (void)onOnEncodedSyncPData:(SDLOnEncodedSyncPData *)notification;
- (void)onOnHashChange:(SDLOnHashChange *)notification;
- (void)onOnLanguageChange:(SDLOnLanguageChange *)notification;
- (void)onOnSyncPData:(SDLOnSyncPData *)notification;
- (void)onOnSystemRequest:(SDLOnSystemRequest *)notification;
- (void)onOnTBTClientState:(SDLOnTBTClientState *)notification;
- (void)onOnTouchEvent:(SDLOnTouchEvent *)notification;
 
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
- (void)onReceivedLockScreenIcon:(UIImage *)icon;
- (void)onPerformAudioPassThruResponse:(SDLPerformAudioPassThruResponse *)response;
- (void)onPerformInteractionResponse:(SDLPerformInteractionResponse *)response;
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
- (void)onSyncPDataResponse:(SDLSyncPDataResponse *)response;
- (void)onUpdateTurnListResponse:(SDLUpdateTurnListResponse *)response;
- (void)onUnregisterAppInterfaceResponse:(SDLUnregisterAppInterfaceResponse *)response;
- (void)onUnsubscribeButtonResponse:(SDLUnsubscribeButtonResponse *)response;
- (void)onUnsubscribeVehicleDataResponse:(SDLUnsubscribeVehicleDataResponse *)response;
*/

@end
