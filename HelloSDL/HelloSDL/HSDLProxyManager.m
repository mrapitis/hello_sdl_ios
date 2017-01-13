//
//  HSDLProxyManager.m
//  HelloSDL
//
//  Created by Ford Developer on 10/5/15.
//  Copyright © 2015 Ford. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SDLDebugTool+ObjectLogging.h"
#import "HSDLProxyManager.h"

#warning TODO: Change these to match your app settings!!
// TCP/IP (Emulator) configuration
static NSString *const RemoteIpAddress = @"192.168.1.201";
static NSString *const RemotePort = @"12345";

// App configuration
static NSString *const AppName = @"SyncProxyTester";
static NSString *const AppId = @"584421907";
static const BOOL AppIsMediaApp = NO;
static NSString *const ShortAppName = @"SPT";
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
        _graphicsSupported = NO;
        _firstHmiFull = YES;
        _firstHmiNotNone = YES;
        _remoteImages = [[NSMutableSet alloc] init];
        _requestBuffer = [[NSMutableDictionary alloc] init];
        _finalVehicleDataArray = [[NSMutableArray alloc] init];
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
#pragma mark custom methods

- (void)sendAndPostRPCMessage:(SDLRPCRequest *)rpcMsg {
    [self postToConsoleLog:rpcMsg];
    [self.proxy sendRPC:rpcMsg];
}

- (void)postToConsoleLog:(id) object {
    [SDLDebugTool logMessage:object withType:SDLDebugType_Debug];
}

#pragma mark Proxy Lifecycle

/**
 *  Start listening for SDL connections. Use only one of the following connection methods.
 */
- (void)startProxy {
    NSLog(@"startProxy");
    
    // If connecting via USB (to a vehicle).
    self.proxy = [SDLProxyFactory buildSDLProxyWithListener:self];

    // If connecting via TCP/IP (to an emulator).
//    self.proxy = [SDLProxyFactory buildSDLProxyWithListener:self tcpIPAddress:RemoteIpAddress tcpPort:RemotePort];
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

    // Build and send RegisterAppInterface request
    SDLRegisterAppInterface *raiRequest = [SDLRPCRequestFactory buildRegisterAppInterfaceWithAppName:AppName languageDesired:[SDLLanguage EN_US] appID:AppId];
    raiRequest.isMediaApplication = @(AppIsMediaApp);
    raiRequest.ngnMediaScreenAppName = ShortAppName;
    raiRequest.vrSynonyms = [NSMutableArray arrayWithObject:AppVrSynonym];
    NSMutableArray *ttsName = [NSMutableArray arrayWithObject:[SDLTTSChunkFactory buildTTSChunkForString:AppName type:SDLSpeechCapabilities.TEXT]];
    raiRequest.ttsName = ttsName;
    [self sendAndPostRPCMessage:raiRequest];
}

/**
 *  Delegate method that runs on disconnect from SDL.
 */
- (void)onProxyClosed {
    NSLog(@"SDL Disconnect");

    // Reset state variables
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
    [self startProxy];
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
    [self sendAndPostRPCMessage:show];

    SDLSpeak *speak = [SDLRPCRequestFactory buildSpeakWithTTS:WelcomeSpeak correlationID:[self hsdl_getNextCorrelationId]];
    [self sendAndPostRPCMessage:speak];
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
    [self sendAndPostRPCMessage:list];
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
                [self sendAndPostRPCMessage:putFile];
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
    [self sendAndPostRPCMessage:setIcon];
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
    [self sendAndPostRPCMessage:command];
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
        [self sendAndPostRPCMessage:show];

        SDLSpeak *speak = [SDLRPCRequestFactory buildSpeakWithTTS:@"Test Command" correlationID:[self hsdl_getNextCorrelationId]];
        [self sendAndPostRPCMessage:speak];
    }
}

#pragma mark VehicleData

- (void)onOnVehicleData:(SDLOnVehicleData *)notification {
    [self postToConsoleLog:notification];
}

- (void)onGetVehicleDataResponse:(SDLGetVehicleDataResponse *)response {
    [self postToConsoleLog:response];
}

- (void)onSubscribeVehicleDataResponse:(SDLSubscribeVehicleDataResponse *)response {
    [self postToConsoleLog:response];
    NSNumber *currentSubMenuCorrelationID = response.correlationID;
    if ([response.resultCode isEqualToEnum:SDLResult.SUCCESS]) {
        //adding only the name to finalButtonArray
        NSString *fullName= [NSString stringWithFormat:@"%@",[[[HSDLProxyManager manager] requestBuffer] objectForKey:currentSubMenuCorrelationID]];
        if (![_finalVehicleDataArray containsObject:fullName]) {
            [_finalVehicleDataArray addObject:fullName];
        }
    }
    //remove that button from main dictionary
    [[[HSDLProxyManager manager] requestBuffer] removeObjectForKey:currentSubMenuCorrelationID];
}

- (void)onUnsubscribeVehicleDataResponse:(SDLUnsubscribeVehicleDataResponse *)response {
    [self postToConsoleLog:response];
    if ([response.resultCode isEqualToEnum:SDLResult.SUCCESS]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"com.sdl.notification.unsubscribeVehicleData" object:nil];
    }
}


@end
