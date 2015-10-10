//
//  HSDLHMIManager.m
//  HelloSDL
//
//  Created by James Sokoll on 10/8/15.
//  Copyright © 2015 Ford Motor Company. All rights reserved.
//

#import "HSDLHMIManager.h"
#import "SDLNotificationConstants.h"

static NSString *const iconFile = @"icon.png";
static const NSUInteger testCommandID = 1;

@interface HSDLHMIManager ()

@property (nonatomic, assign) BOOL graphics;
@property (nonatomic, strong) NSMutableSet *remoteImages;

@end

@implementation HSDLHMIManager

// Singleton method
+ (instancetype)sharedManager
{
    static HSDLHMIManager *hmiManager = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        hmiManager = [[self alloc] init];
    });

    return hmiManager;
}

- (instancetype)init
{
    if (self = [super init]) {
        _graphics = NO;
        _remoteImages = [[NSMutableSet alloc] init];
        [self registerForSDLNotifications];
    }

    return self;
}

#pragma mark Notification management
- (void)registerForSDLNotifications
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

    [center addObserver:self selector:@selector(didRegister:) name:SDLDidRegisterNotification object:nil];
    [center addObserver:self selector:@selector(didReceiveFirstFullHMIStatus:) name:SDLDidReceiveFirstFullHMIStatusNotification object:nil];
    [center addObserver:self selector:@selector(didReceiveFirstNonNoneHMIStatus:) name:SDLDidReceiveFirstNonNoneHMIStatusNotification object:nil];
    [center addObserver:self selector:@selector(didDisconnect:) name:SDLDidDisconnectNotification object:nil];
    [center addObserver:self selector:@selector(didReceiveCommand:) name:SDLDidReceiveCommandNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)uploadImages
{
    // Uploads images to SYNC
    // Called automatically by the didRegister: method

    // Note: Don't need to check for graphics support here; it is checked by the caller
    [SDLDebugTool logInfo:@"uploadImages"];
    __weak typeof(self) weakSelf = self;
    [self.remoteImages removeAllObjects];

    // Perform a ListFiles RPC to check which files are already present on SYNC
    SDLListFiles *list = [[SDLListFiles alloc] init];
    SDLRequestCompletionHandler listHandler = ^(SDLRPCRequest *rpcRequest, SDLRPCResponse *rpcResponse, NSError *error) {
        // ListFiles completion handler
        __strong typeof(self) strongSelf = weakSelf;
        if (strongSelf) {
            SDLListFilesResponse *response = (SDLListFilesResponse *)rpcResponse;

            // If the ListFiles was successfull, store the list in a mutable array
            if (response.success) {
                for (NSString *filename in response.filenames) {
                    [strongSelf.remoteImages addObject:filename];
                }
            }

            // Check the mutable array for the AppIcon
            // If not present, upload the image
            if (![strongSelf.remoteImages containsObject:iconFile]) {
                SDLRequestCompletionHandler appIconHandler = ^(SDLRPCRequest *rpcRequest, SDLRPCResponse *rpcResponse, NSError *error) {
                    if (strongSelf) {
                        SDLPutFileResponse *response = (SDLPutFileResponse *)rpcResponse;
                        // On success, send a SetAppIcon request
                        if (response.success) {
                            [strongSelf setAppIcon];
                        }
                    }
                };
                [strongSelf uploadImage:iconFile completionHandler:appIconHandler];
            }
            // If the file is already present, send the SetAppIcon request
            else {
                [strongSelf setAppIcon];
            }
        }
    };
    [[SDLManager sharedManager] sendRequest:list withCompletionHandler:listHandler];
}

- (void)uploadImage:(NSString *)imageName completionHandler:(SDLRequestCompletionHandler)handler
{
    // Upload an image from the App's Assets with the specified name and completion handler
    // Note: Assumes a PNG image type, and persistent storage!!

    [SDLDebugTool logInfo:[NSString stringWithFormat:@"uploadImage: %@", imageName]];
    if (imageName) {
        UIImage *pngImage = [UIImage imageNamed:iconFile];
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
                [[SDLManager sharedManager] sendRequest:putFile withCompletionHandler:handler];
            }
        }
    }
}

- (void)setAppIcon
{
    // Sends the SetAppIcon RPC with the image name uploaded via uploadImages
    // Called automatically in the PutFile response handler
    [SDLDebugTool logInfo:@"setAppIcon"];
    SDLSetAppIcon *setIcon = [[SDLSetAppIcon alloc] init];
    setIcon.syncFileName = iconFile;
    [[SDLManager sharedManager] sendRequest:setIcon withCompletionHandler:nil];
}

- (void)didRegister:(NSNotification *)notification
{
    // Notification method to perform actions on successful registration with SYNC

    SDLRegisterAppInterfaceResponse *registerResponse = nil;
    if (notification && notification.userInfo) {
        registerResponse = notification.userInfo[SDLNotificationUserInfoNotificationObject];
    }

    // Check for graphics capability, and upload persistent graphics (app icon) if available
    if (registerResponse && registerResponse.displayCapabilities) {
        if (registerResponse.displayCapabilities.graphicSupported) {
            self.graphics = [registerResponse.displayCapabilities.graphicSupported boolValue];
        }
    }

    if (self.graphics) {
        [self uploadImages];
    }
}

- (void)didReceiveFirstFullHMIStatus:(NSNotification *)notification
{
    // Notification method to perform actions on the first HMI_FULL status notification from SYNC

    SDLOnHMIStatus *status = nil;
    if (notification && notification.userInfo) {
        status = notification.userInfo[SDLNotificationUserInfoNotificationObject];
    }

    // Send welcome message (Speak and Show)
    SDLShow *show = [[SDLShow alloc] init];
    show.mainField1 = @"Welcome to HelloSDL";
    show.alignment = [SDLTextAlignment CENTERED];
    [[SDLManager sharedManager] sendRequest:show withCompletionHandler:nil];

    SDLSpeak *speak = [SDLRPCRequestFactory buildSpeakWithTTS:@"Welcome to Hello S D L" correlationID:nil];
    [[SDLManager sharedManager] sendRequest:speak withCompletionHandler:nil];
}

- (void)didReceiveFirstNonNoneHMIStatus:(NSNotification *)notification
{
    // Notification method to perform actions on the first non-HMI_NONE status notification from SYNC

    SDLOnHMIStatus *status = nil;
    if (notification && notification.userInfo) {
        status = notification.userInfo[SDLNotificationUserInfoNotificationObject];
    }

    // Create AddCommand
    SDLAddCommand *command = [[SDLAddCommand alloc] init];
    SDLMenuParams *menuParams = nil;
    menuParams = [[SDLMenuParams alloc] init];
    command.vrCommands = [NSMutableArray arrayWithObject:@"Test Command"];
    menuParams.menuName = @"Test Command";
    command.menuParams = menuParams;
    command.cmdID = @(testCommandID);

    [[SDLManager sharedManager] sendRequest:command withCompletionHandler:nil];

    // Command event handler
    // Send AddCommand with response handler
    [[SDLManager sharedManager] sendRequest:command
                      withCompletionHandler:^(SDLRPCRequest *request, SDLRPCResponse *response, NSError *error) {
                          // Check if command was added successfully
                          [SDLDebugTool logInfo:[NSString stringWithFormat:@"AddCommand Response: %@", response]];
                      }];
}

- (void)didDisconnect:(NSNotification *)notification
{
    // Notification method to perform actions on disconnect from SYNC

    // Cleanup state variables
    self.graphics = NO;
    [self.remoteImages removeAllObjects];
}

- (void)didReceiveCommand:(NSNotification *)notification
{

    SDLAddCommandResponse *addCommandResponse = nil;
    if (notification && notification.userInfo) {
        addCommandResponse = notification.userInfo[SDLNotificationUserInfoNotificationObject];
    }

    if (addCommandResponse) {
        [SDLDebugTool logInfo:[NSString stringWithFormat:@"Test Command: %@", notification]];
        SDLShow *show = [[SDLShow alloc] init];
        show.mainField1 = @"Test Command";
        show.alignment = [SDLTextAlignment CENTERED];
        [[SDLManager sharedManager] sendRequest:show withCompletionHandler:nil];

        SDLSpeak *speak = [SDLRPCRequestFactory buildSpeakWithTTS:@"Test Command" correlationID:nil];
        [[SDLManager sharedManager] sendRequest:speak withCompletionHandler:nil];
    }

    [SDLDebugTool logInfo:@"didReceiveCommand"];
}

@end
