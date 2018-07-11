//
//  TestScreenManagerViewController.m
//  HelloSDL
//
//  Created by CHDSEZ318988DADM on 11/07/18.
//  Copyright © 2018 Ford. All rights reserved.
//

#import "TestScreenManagerViewController.h"
#import "HSDLProxyManager.h"

@interface TestScreenManagerViewController ()

@end

@implementation TestScreenManagerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)sendShowRPCAction:(id)sender {

    SDLMetadataTags *metadataTags = [[SDLMetadataTags alloc] initWithTextFieldTypes:@[SDLMetadataTypeMediaYear] mainField2:@[SDLMetadataTypeMediaArtist]];

    SDLShow *req = [[SDLShow alloc] initWithMainField1:@"Show RPC field 1" mainField2:@"Show RPC field 2" mainField3:@"Show RPC field 3" mainField4:@"Show RPC field 4" alignment:SDLTextAlignmentCenter statusBar:@"Show status bar" mediaClock:nil mediaTrack:@"Show media track" graphic:nil softButtons:[self softButtons] customPresets:nil textFieldMetadata:metadataTags];
    [[HSDLProxyManager sharedManager].manager sendRequest:req withResponseHandler:^(__kindof SDLRPCRequest * _Nullable request, __kindof SDLRPCResponse * _Nullable response, NSError * _Nullable error) {
        NSLog(@"%@",response);
    }];
}

- (NSMutableArray*)softButtons {
    NSMutableArray *softButtons = [[NSMutableArray alloc] init];
        SDLSoftButton *sb1 = [[SDLSoftButton alloc] init];
        sb1.softButtonID = [NSNumber numberWithInt:5500];
        sb1.text = @"One";
        sb1.image = [[SDLImage alloc] init];
        sb1.image.imageType = SDLImageTypeStatic;
        sb1.image.value = @"9";
        sb1.type = SDLSoftButtonTypeBoth;
        sb1.isHighlighted = [NSNumber numberWithBool:false];
        sb1.systemAction = SDLSystemActionKeepContext;
        sb1.handler = ^(SDLOnButtonPress *_Nullable buttonPress,  SDLOnButtonEvent *_Nullable buttonEvent){
            NSLog(@"button pressed %@",buttonPress);
        };

        SDLSoftButton *sb2 = [[SDLSoftButton alloc] init];
        sb2.softButtonID = [NSNumber numberWithInt:5501];
        sb2.text = @"Two";
        sb2.type = SDLSoftButtonTypeText;
        sb2.isHighlighted = [NSNumber numberWithBool:true];
        sb2.systemAction = SDLSystemActionDefaultAction;
        sb2.handler = ^(SDLOnButtonPress *_Nullable buttonPress,  SDLOnButtonEvent *_Nullable buttonEvent){
            NSLog(@"button pressed %@",buttonPress);
        };

        softButtons = [@[sb1, sb2] mutableCopy];

    return softButtons;
}

- (IBAction)sendSetDisplayLayoutRPC:(id)sender {
    SDLSetDisplayLayout* req = [[SDLSetDisplayLayout alloc] initWithLayout:SDLPredefinedLayoutDefault];
    [[HSDLProxyManager sharedManager].manager sendRequest:req withResponseHandler:^(__kindof SDLRPCRequest * _Nullable request, __kindof SDLRPCResponse * _Nullable response, NSError * _Nullable error) {
        NSLog(@"%@",response);
    }];
}

- (IBAction)updateHMIScreen:(id)sender {

    [[HSDLProxyManager sharedManager].manager.screenManager beginUpdates];
    SDLTextAlignment textAlignment = SDLTextAlignmentLeft;

    [HSDLProxyManager sharedManager].manager.screenManager.textAlignment = textAlignment;
    [HSDLProxyManager sharedManager].manager.screenManager.textField1 = @"Manager textField1";
   [HSDLProxyManager sharedManager].manager.screenManager.textField2 = @"Manager textField2";
    [HSDLProxyManager sharedManager].manager.screenManager.textField3 = @"Manager textField3";
    [HSDLProxyManager sharedManager].manager.screenManager.textField4 = @"Manager textField4";
    [HSDLProxyManager sharedManager].manager.screenManager.mediaTrackTextField = @"Manager media TextField";

    [HSDLProxyManager sharedManager].manager.screenManager.softButtonObjects = [self getShowSoftButtonObjects];

    [HSDLProxyManager sharedManager].manager.screenManager.textField1Type = SDLMetadataTypeMediaTitle;
    [HSDLProxyManager sharedManager].manager.screenManager.textField2Type = SDLMetadataTypeMediaAlbum;
    [HSDLProxyManager sharedManager].manager.screenManager.textField3Type = SDLMetadataTypeMediaArtist;
   [HSDLProxyManager sharedManager].manager.screenManager.textField4Type = SDLMetadataTypeMediaYear;

    [[HSDLProxyManager sharedManager].manager.screenManager endUpdatesWithCompletionHandler:^(NSError * _Nullable error) {
        NSLog(@"Updated text and graphics, error? %@", error);
    }];
}

- (NSMutableArray *)getShowSoftButtonObjects {
    NSMutableArray *softButtonObjects = [[NSMutableArray alloc] init];
    SDLSoftButtonState *btnState1 = [[SDLSoftButtonState alloc] initWithStateName:@"State 1" text:@"SM Text" image:nil];
    btnState1.highlighted = NO;

    SDLSoftButtonObject *obj1 = [[SDLSoftButtonObject alloc] initWithName:@"ScreenManager softBtn" state:btnState1 handler:^(SDLOnButtonPress * _Nullable buttonPress, SDLOnButtonEvent * _Nullable buttonEvent) {
        NSLog(@"button pressed %@",buttonPress);
    }];
    [softButtonObjects addObject:obj1];

    return  softButtonObjects;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
