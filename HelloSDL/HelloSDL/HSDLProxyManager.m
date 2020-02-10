//
//  HSDLProxyManager.m
//  HelloSDL
//
//  Created by Ford Developer on 10/5/15.
//  Copyright © 2015 Ford. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HSDLProxyManager.h"

static NSString *const IconFile = @"sdl_icon.png";
static NSString *const lockScreenKey = @"lockScreenEnabled";

// Welcome message
static NSString *const WelcomeShow = @"Welcome to HelloSDL";
static NSString *const WelcomeSpeak = @"Welcome to Hello S D L";

// Sample AddCommand
static NSString *const TestCommandName = @"Test Command";
static const NSUInteger TestCommandID = 1;

@interface HSDLProxyManager () <SDLManagerDelegate,SDLNotificationDelegate>

@property (nonatomic, strong) SDLManager *manager;
@property (strong, nonatomic) HSDLHMIStatusHandler hmiHandler;
@property (nonatomic, assign, getter=isGraphicsSupported) BOOL graphicsSupported;
@property (nonatomic, assign, getter=isFirstHmiNotNone) BOOL firstHmiNotNone;
@property (nonatomic, assign, getter=isVehicleDataSubscribed) BOOL vehicleDataSubscribed;

@end

@implementation HSDLProxyManager

#pragma mark Lifecycle



- (instancetype)initWithLifeCycleConfiguration:(SDLLifecycleConfiguration *)lifecycleConfig  withHMIStatusHandler:(HSDLHMIStatusHandler) hmiHandler {
    if (self = [super init]) {
        _graphicsSupported = NO;
        _firstHmiNotNone = YES;
        _vehicleDataSubscribed = NO;

        // SDLConfiguration contains the lifecycle and lockscreen configurations
        SDLTTSChunk *ttsChunk = [[SDLTTSChunk alloc] init];
        ttsChunk.text  = lifecycleConfig.appName;
        ttsChunk.type = SDLSpeechCapabilitiesText;
        lifecycleConfig.ttsName = @[ttsChunk];

        UIImage* appIcon = [UIImage imageNamed:IconFile];
        if (appIcon) {
            lifecycleConfig.appIcon = [SDLArtwork artworkWithImage:appIcon name:IconFile asImageFormat:SDLArtworkImageFormatPNG];
        }

        SDLLockScreenConfiguration *lockScreenConfig;
        if ([[self _numberForKey:lockScreenKey
        withDefaultValue:@(NO)] boolValue]) {
            lockScreenConfig = [SDLLockScreenConfiguration enabledConfiguration];
        } else {
            lockScreenConfig = [SDLLockScreenConfiguration disabledConfiguration];
        }

        SDLLogConfiguration *logConfig = [SDLLogConfiguration defaultConfiguration];
        logConfig.disableAssertions = YES;

        SDLConfiguration *configuration = [SDLConfiguration configurationWithLifecycle:lifecycleConfig lockScreen:lockScreenConfig logging:logConfig fileManager:nil];
        
        _manager = [[SDLManager alloc] initWithConfiguration:configuration delegate:self];
        
        [self sdl_addRPCObservers];
        self.hmiHandler = hmiHandler;
    }
    return self;
}


- (NSNumber*)_numberForKey:(NSString*)key withDefaultValue:(NSNumber*)defaultValue {
    NSNumber* numberObject = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if ([numberObject isKindOfClass:[NSString class]]) {
        NSString* numberString = (NSString*)numberObject;
        numberObject = [self.numberFormatter numberFromString:numberString];
    }
    if (!numberObject) {
        numberObject = defaultValue;
        [[NSUserDefaults standardUserDefaults] setObject:numberObject
                              forKey:key];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    return numberObject;
}

- (NSNumberFormatter*)numberFormatter {
    static NSNumberFormatter* numberFormatter = nil;
    if (!numberFormatter) {
        numberFormatter = [[NSNumberFormatter alloc] init];
        numberFormatter.formatterBehavior = NSNumberFormatterDecimalStyle;
    }
    return numberFormatter;
}

#pragma mark Proxy Lifecycle

/**
 *  Start listening for SDL connections. Use only one of the following connection methods.
 */
- (void)start {
    NSLog(@"starting proxy manager");
    [self.manager startWithReadyHandler:^(BOOL success, NSError * _Nullable error) {
        if (!success) {
            NSLog(@"There was an error! %@", error.localizedDescription);
            return;
        }

        NSLog(@"Successfully connected!");
        self.hmiHandler(self.manager.hmiLevel);
        [self sdl_addPermissionManagerObservers];
    }];

}

/**
 *  Disconnect and destroy the current proxy.
 */
- (void)stop {
    NSLog(@"stopping proxy manager");
    [self.manager stop];
}


#pragma mark - SDLManagerDelegate
- (void)hmiLevel:(SDLHMILevel)oldLevel didChangeToLevel:(SDLHMILevel)newLevel {
    NSLog(@"HMIStatus notification from SDL");
    self.hmiHandler(newLevel);
    // Send AddCommands in first non-HMI NONE state (i.e., FULL, LIMITED, BACKGROUND)
    if (![newLevel isEqualToEnum:SDLHMILevelNone] && self.isFirstHmiNotNone == YES) {
        _firstHmiNotNone = NO;
        [self sdl_addCommands];
        
        // Other app setup (SubMenu, CreateChoiceSet, etc.) would go here
        // NOTE: Keep the number of RPCs small, as there is a limit in HMI_NONE!
    }
    
    // Send welcome message on first HMI FULL
    if ([newLevel isEqualToEnum:SDLHMILevelFull]) {
        if ([oldLevel isEqualToEnum:SDLHMILevelNone]) {
            [self sdl_performWelcomeMessage];
            return;
        }
        
        // Other HMI (Show, PerformInteraction, etc.) would go here
    }
}

- (void)managerDidDisconnect {
    NSLog(@"Manager did disconnect");
    _firstHmiNotNone = YES;
    _vehicleDataSubscribed = NO;
    _graphicsSupported = NO;

    self.hmiHandler(@"");
}

#pragma mark - Observers
- (void)sdl_addRPCObservers {
    // Adding Response Observers
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveRegisterAppInterfaceResponse:) name:SDLDidReceiveRegisterAppInterfaceResponse object:nil];
    
    // Adding Notification Observers
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveVehicleData:) name:SDLDidReceiveVehicleDataNotification object:nil];
}

- (void)sdl_addPermissionManagerObservers {
    // Adding Permission Manager Observers
    // Since we do not want to remove the observer, we will not store the UUID it returns
    __weak typeof(self) weakSelf = self;
    [self.manager.permissionManager addObserverForRPCs:@[@"SubscribeVehicleData"] groupType:SDLPermissionGroupTypeAllAllowed withHandler:^(NSDictionary<SDLPermissionRPCName,NSNumber<SDLBool> *> * _Nonnull change, SDLPermissionGroupStatus status) {
            if (status != SDLPermissionGroupStatusAllowed) {
                return;
            }

            typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf.isVehicleDataSubscribed == NO) {
                [strongSelf sdl_subscribeVehicleData];
            }
    }];
}

- (void)didReceiveVehicleData:(SDLRPCNotificationNotification *)notification {
    SDLOnVehicleData *onVehicleData = notification.notification;
    if (!onVehicleData || ![onVehicleData isKindOfClass:SDLOnVehicleData.class]) {
        return;
    }
    
    NSLog(@"OnVehicleData notification from SDL");
    
    // TODO: Put your vehicle data code here!
    NSLog(@"Speed: %@", onVehicleData.speed);
}

- (void)didReceiveRegisterAppInterfaceResponse:(SDLRPCResponseNotification *)notification {
    SDLRegisterAppInterfaceResponse *response = notification.response;
    if (!response || ![response isKindOfClass:SDLRegisterAppInterfaceResponse.class]) {
        return;
    }
    
    _graphicsSupported = response.displayCapabilities.graphicSupported.boolValue;
    
    if (self.isGraphicsSupported) {
        // Send images via SDLFileManager
    }
}

#pragma mark - Subscribers & HMI Setup
#pragma mark Vehicle Data
/**
 Subscribe to (periodic) vehicle data updates from SDL.
 */
- (void)sdl_subscribeVehicleData {
    NSLog(@"sdl_subscribeVehicleData");
    if (self.isVehicleDataSubscribed) {
        return;
    }
    
    SDLSubscribeVehicleData *subscribe = [[SDLSubscribeVehicleData alloc] init];
    
    // TODO: Add the vehicle data items you want to subscribe to
    // Specify which items to subscribe to
    subscribe.speed = @YES;
    
    [self.manager sendRequest:subscribe withResponseHandler:^(__kindof SDLRPCRequest * _Nullable request, __kindof SDLRPCResponse * _Nullable response, NSError * _Nullable error) {
        if ([response.resultCode isEqualToEnum:SDLResultSuccess]) {
            NSLog(@"Vehicle Data Subscribed!");
            _vehicleDataSubscribed = YES;
        }
    }];
}

#pragma mark HMI

/**
 Send welcome message (Speak and Show).
 */
- (void)sdl_performWelcomeMessage {
    NSLog(@"Send welcome message");
    SDLShow *show = [[SDLShow alloc] init];
    show.mainField1 = WelcomeShow;
    show.alignment = SDLTextAlignmentCenter;
    [self.manager sendRequest:show];

    SDLSpeak *speak = [[SDLSpeak alloc] initWithName:WelcomeSpeak];
    [self.manager sendRequest:speak];
}

#pragma mark Commands

/**
 Add commands for the app on SDL.
 */
- (void)sdl_addCommands {
    NSLog(@"sdl_addCommands");
    __weak typeof(self) weakSelf = self;
    SDLAddCommand *command = [[SDLAddCommand alloc] initWithHandler:^(__kindof SDLRPCNotification * _Nonnull notification) {
        if (![notification isKindOfClass:SDLOnCommand.class]) {
            return;
        }

        typeof(weakSelf) strongSelf = weakSelf;

        SDLOnCommand* onCommand = (SDLOnCommand *)notification;

        if (onCommand.cmdID.unsignedIntegerValue == TestCommandID) {
            SDLShow *show = [[SDLShow alloc] init];
            show.mainField1 = @"Test Command";
            show.alignment = SDLTextAlignmentCenter;
            [strongSelf.manager sendRequest:show];

            SDLSpeak* speak = [[SDLSpeak alloc] initWithName:@"Test Command"];
            [strongSelf.manager sendRequest:speak];
        }
    }];
    command.cmdID = [NSNumber numberWithInt:TestCommandID];
    command.vrCommands = @[TestCommandName].mutableCopy;
    SDLMenuParams *params = [[SDLMenuParams alloc] init];
    params.menuName = TestCommandName;
    command.menuParams = params;
    
    [self.manager sendRequest:command withResponseHandler:^(__kindof SDLRPCRequest * _Nullable request, __kindof SDLRPCResponse * _Nullable response, NSError * _Nullable error) {
        NSLog(@"AddCommand response from SDL: %@ with info: %@", response.resultCode, response.info);
    }];
}


- (void)sendRPCNotificationObject:(nonnull SDLRPCNotificationNotification *)notification {
    if ([notification.notification isKindOfClass:SDLOnHMIStatus.class]) {
        SDLOnHMIStatus *hmiStatus = (SDLOnHMIStatus *)notification.notification;
        self.hmiHandler(hmiStatus.hmiLevel);
    } if ([notification.notification isKindOfClass:SDLOnAppInterfaceUnregistered.class]) {
        self.hmiHandler(@"stop");
    }
}

@end
