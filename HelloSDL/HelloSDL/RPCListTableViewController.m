//
//  RPCListTableViewController.m
//  HelloSDL
//
//  Created by CHDSEZ318988DADM on 09/01/17.
//  Copyright © 2017 Ford. All rights reserved.
//

#import "RPCListTableViewController.h"

static NSString* const RPCTableViewCellIdentifier = @"RPCTableViewCell";

@interface RPCListTableViewController ()
@property(strong,nonatomic) NSArray* rpcIdentifiers;
@property (nonatomic, strong) NSMutableDictionary* viewControllerCache;

@end

@implementation RPCListTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerClass:[UITableViewCell class]
           forCellReuseIdentifier:RPCTableViewCellIdentifier];
    _rpcIdentifiers = @[
                        @"GetVehicleData",
                        @"SubscribeVehicleData",
                        @"UnsubscribeVehicleData",
                        ];
    self.viewControllerCache = [NSMutableDictionary dictionary];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.rpcIdentifiers count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:RPCTableViewCellIdentifier forIndexPath:indexPath];
    cell.textLabel.text = _rpcIdentifiers[indexPath.row];
    // Configure the cell...
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString* cacheKey = _rpcIdentifiers[indexPath.row];
    UIViewController* viewController = [self spt_viewControllerForKey:cacheKey];
    if (viewController) {
        [self.navigationController pushViewController:viewController animated:YES];
    } else {
        NSLog(@"Error trying to present %@", cacheKey);
    }
}

- (UIViewController*)spt_viewControllerForKey:(NSString*)key {
    UIViewController* viewController = self.viewControllerCache[key];
    if (!viewController) {
        NSString* viewControllerClassString = [NSString stringWithFormat:@"%@ViewController", key];
        Class viewControllerClass = NSClassFromString(viewControllerClassString);
        if (viewControllerClass) {
            viewController = [self.storyboard instantiateViewControllerWithIdentifier:viewControllerClassString];
            self.viewControllerCache[key] = viewController;
        }
    }
    return viewController;
}
@end
