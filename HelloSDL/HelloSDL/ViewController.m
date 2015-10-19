//
//  ViewController.m
//  HelloSDL
//
//  Created by Ford Developer on 10/5/15.
//  Copyright © 2015 Ford. All rights reserved.
//

#import "ViewController.h"
#import "HSDLProxyManager.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)connectDidTouchUpInside:(id)sender {
    // This button/method is only needed when using TCP/IP transport
    // since it tries to connect immediately after being instantiated
    [[HSDLProxyManager manager] startProxy];
}

- (IBAction)disconnectDidTouchUpInside:(id)sender {
    // This button/method is only needed when using TCP/IP transport
    [[HSDLProxyManager manager] manualDisconnect];
}

@end
