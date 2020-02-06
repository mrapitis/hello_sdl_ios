//
//  ViewController.m
//  HelloSDL
//
//  Created by Ford Developer on 10/5/15.
//  Copyright © 2015 Ford. All rights reserved.
//

#import "ViewController.h"
#import "HSDLProxyManager.h"
#import <SmartDeviceLink/SDLLifecycleConfiguration.h>


#warning TODO: Change these to match your app settings!!

// App configuration
static NSString *const AppName = @"HelloSDL";
static NSString *const AppId = @"8675309";
static const BOOL AppIsMediaApp = NO;
static NSString *const ShortAppName = @"Hello";
static NSString *const AppVrSynonym = @"Hello S D L";

// TCP/IP (Emulator) configuration
static NSString *const RemoteIpAddress = @"127.0.0.1";
static UInt16 const RemotePort = 12345;

@interface ViewController ()
@property (strong, nonatomic) NSMutableArray *appArray;
@property (weak, nonatomic) IBOutlet UILabel *hmiStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *hmiStatus1Label;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _appArray = [NSMutableArray arrayWithObjects:[self getAppWithAppName:AppName appID:AppId shortAppName:ShortAppName vrSynonym:AppVrSynonym],[self getAppWithAppName:[AppName stringByAppendingString:@"1"] appID:[NSString stringWithFormat:@"%d",(AppId.intValue+1)] shortAppName:[ShortAppName stringByAppendingString:@"1"] vrSynonym:[AppVrSynonym stringByAppendingString:@"1"]], nil];
    // Do any additional setup after loading the view, typically from a nib.
}

- (HSDLProxyManager *)getAppWithAppName:(NSString *)appname appID:(NSString *)appID shortAppName:(NSString *)shortAppName vrSynonym:(NSString *)vrSynonym {
    HSDLProxyManager *proxymanager = [[HSDLProxyManager alloc] initWithLifeCycleConfiguration:[self getLifecycleConfigurationForAppName:appname appID:appID shortAppName:shortAppName vrSynonym:vrSynonym] withHMIStatusHandler:^(__kindof NSString *hmiStatus) {
        if ([appname isEqualToString:AppName]) {
            [self updateLableWithTag:1 andHMIStatus:hmiStatus];
        } else {
            [self updateLableWithTag:2 andHMIStatus:hmiStatus];
        }
    }];
    return proxymanager;
}
                                       

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)connectHelloSDL:(id)sender {
    UIButton *btn = (UIButton *)sender;
    HSDLProxyManager *proxymanager = [_appArray objectAtIndex:(btn.tag - 1)];
    NSString *btnLabel = btn.titleLabel.text;
    
    if ([btnLabel isEqualToString:@"Stop"]) {
        [proxymanager stop];
    } else {
        [proxymanager start];
    }
//
    [btn setTitle:@"Connect" forState:UIControlStateNormal];
}

- (SDLLifecycleConfiguration *)getLifecycleConfigurationForAppName:(NSString *)appname appID:(NSString *)appID shortAppName:(NSString *)shortAppName vrSynonym:(NSString *)vrSynonym {

//    If connecting via USB (to a vehicle).

    SDLLifecycleConfiguration *lifecycleConfiguration =  [SDLLifecycleConfiguration defaultConfigurationWithAppName:appname appId:appID];

//    If connecting via TCP/IP (to an emulator).
//    SDLLifecycleConfiguration *lifecycleConfiguration = [SDLLifecycleConfiguration debugConfigurationWithAppName:AppName appId:AppId ipAddress:RemoteIpAddress port:RemotePort];

             lifecycleConfiguration.appType = AppIsMediaApp ? SDLAppHMIType.MEDIA : SDLAppHMIType.DEFAULT;
             lifecycleConfiguration.shortAppName = shortAppName;
             lifecycleConfiguration.voiceRecognitionCommandNames = @[vrSynonym];

    return lifecycleConfiguration;
}



- (void)updateLableWithTag:(int)tag andHMIStatus:(NSString *)hmiStatus {
    if (tag == 1) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIButton *btn = (UIButton *)[self.view viewWithTag:tag];
            if ([self.hmiStatusLabel.text isEqualToString:@"Not Connected"]|| ![btn.titleLabel.text isEqualToString:@"Stop"]) {
                [self.hmiStatusLabel setText:hmiStatus];
                [btn setTitle:@"Stop" forState:UIControlStateNormal];
            } else {
                [self.hmiStatusLabel setText:@"Not Connected"];
                [btn setTitle:@"Connect" forState:UIControlStateNormal];
            }

        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIButton *btn = (UIButton *)[self.view viewWithTag:tag];
            if ([self.hmiStatus1Label.text isEqualToString:@"Not Connected"]|| ![btn.titleLabel.text isEqualToString:@"Stop"]) {
                [btn setTitle:@"Stop" forState:UIControlStateNormal];
                [self.hmiStatus1Label setText:hmiStatus];
            } else {
                [self.hmiStatus1Label setText:@"Not Connected"];
                [btn setTitle:@"Connect" forState:UIControlStateNormal];
            }
        });
    }
}



@end
