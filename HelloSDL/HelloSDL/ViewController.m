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
@property (weak, nonatomic) IBOutlet UILabel *lockLabel;

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

- (IBAction)toggleStartAction:(id)sender {
    UIButton *btn = (UIButton *)sender;
    if ([[HSDLProxyManager sharedManager] isConnected]) {
            [[HSDLProxyManager sharedManager] stop];
    } else {
        [[HSDLProxyManager sharedManager] startWithResponseHandler:^(BOOL _isConnected) {
            if (_isConnected) {
                [btn setTitle:@"Stop" forState:UIControlStateNormal];
            } else {
                [btn setTitle:@"Start" forState:UIControlStateNormal];
            }
        }];
    }

}

@end
