//  UnsubscribeVehicleDataViewController.m
//  SyncProxyTester
//  Copyright (c) 2013 Ford Motor Company. All rights reserved.

#import "UnsubscribeVehicleDataViewController.h"
#import "SubscribeVehicleDataViewController.h"
#import "HSDLProxyManager.h"

@interface UnsubscribeVehicleDataViewController () <UITableViewDataSource, UITableViewDelegate> {
    IBOutlet UITableView *vehicleDataTable;
}

@property (weak, nonatomic) NSString *chosenVehicleData;

@end

@implementation UnsubscribeVehicleDataViewController

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    self.chosenVehicleData =  cell.textLabel.text;
    
    SDLUnsubscribeVehicleData *req = [[SDLUnsubscribeVehicleData alloc] init];
    
    if ([self.chosenVehicleData isEqualToString:@"GPS"]) {
        req.gps = [NSNumber numberWithBool:true];
    }
    else if ([self.chosenVehicleData isEqualToString:@"GPS Array"]) {
        req.gpsArray = [NSNumber numberWithBool:true];
    }
    else if ([self.chosenVehicleData isEqualToString:@"Speed"]) {
        req.speed = [NSNumber numberWithBool:true];
    }
    else if ([self.chosenVehicleData isEqualToString:@"Speed Array"]) {
        req.speedArray = [NSNumber numberWithBool:true];
    }
    else if ([self.chosenVehicleData isEqualToString:@"RPM"]) {
        req.rpm = [NSNumber numberWithBool:true];
    }
    else if ([self.chosenVehicleData isEqualToString:@"RPM Array"]) {
        req.rpmArray = [NSNumber numberWithBool:true];
    }
    else if ([self.chosenVehicleData isEqualToString:@"FuelLevel"]) {
        req.fuelLevel = [NSNumber numberWithBool:true];
    }
    else if ([self.chosenVehicleData isEqualToString:@"FuelLevel Array"]) {
        req.fuelLevelArray = [NSNumber numberWithBool:true];
    }
    else if ([self.chosenVehicleData isEqualToString:@"FuelLevelState"]) {
        req.fuelLevel_State = [NSNumber numberWithBool:true];
    }
    else if ([self.chosenVehicleData isEqualToString:@"FuelLevelState Array"]) {
        req.fuelLevel_StateArray = [NSNumber numberWithBool:true];
    }
    else if ([self.chosenVehicleData isEqualToString:@"InstantFuelConsuption"]) {
        req.instantFuelConsumption = [NSNumber numberWithBool:true];
    }
    else if ([self.chosenVehicleData isEqualToString:@"ExternalTemperature"]) {
        req.externalTemperature = [NSNumber numberWithBool:true];
    }
    else if ([self.chosenVehicleData isEqualToString:@"ExternalTemperature Array"]) {
        req.externalTemperatureArray = [NSNumber numberWithBool:true];
    }
    else if ([self.chosenVehicleData isEqualToString:@"PRNDL"]) {
        req.prndl = [NSNumber numberWithBool:true];
    }
    else if ([self.chosenVehicleData isEqualToString:@"PRNDL Array"]) {
        req.prndlArray = [NSNumber numberWithBool:true];
    }
    else if ([self.chosenVehicleData isEqualToString:@"TirePressure"]) {
        req.tirePressure = [NSNumber numberWithBool:true];
    }
    else if ([self.chosenVehicleData isEqualToString:@"TirePressure Array"]) {
        req.tirePressureArray = [NSNumber numberWithBool:true];
    }
    else if ([self.chosenVehicleData isEqualToString:@"Odometer"]) {
        req.odometer = [NSNumber numberWithBool:true];
    }
    else if ([self.chosenVehicleData isEqualToString:@"BeltStatus"]) {
        req.beltStatus = [NSNumber numberWithBool:true];
    }
    else if ([self.chosenVehicleData isEqualToString:@"BodyInformation"]) {
        req.bodyInformation = [NSNumber numberWithBool:true];
    }
    else if ([self.chosenVehicleData isEqualToString:@"DeviceStatus"]) {
        req.deviceStatus = [NSNumber numberWithBool:true];
    }
    else if ([self.chosenVehicleData isEqualToString:@"DriverBraking"]) {
        req.driverBraking = [NSNumber numberWithBool:true];
    }
    else if ([self.chosenVehicleData isEqualToString:@"FuelRemainingRange Array"]) {
        req.fuelRemainingRangeArray = [NSNumber numberWithBool:true];
    }
    else if ([self.chosenVehicleData isEqualToString:@"BrakePedalPosition Array"]) {
        req.brakePedalPositionArray = [NSNumber numberWithBool:true];
    }
    else if ([self.chosenVehicleData isEqualToString:@"WiperStatus"]) {
        req.wiperStatus = [NSNumber numberWithBool:true];
    }
    else if ([self.chosenVehicleData isEqualToString:@"HeadLampStatus"]) {
        req.headLampStatus = [NSNumber numberWithBool:true];
    }
    else if ([self.chosenVehicleData isEqualToString:@"EngineTorque"]) {
        req.engineTorque = [NSNumber numberWithBool:true];
    }
    else if ([self.chosenVehicleData isEqualToString:@"EngineTorque Array"]) {
        req.engineTorqueArray = [NSNumber numberWithBool:true];
    }
    else if ([self.chosenVehicleData isEqualToString:@"AccPedalPosition"]) {
        req.accPedalPosition = [NSNumber numberWithBool:true];
    }
    else if ([self.chosenVehicleData isEqualToString:@"AccPedalPosition Array"]) {
        req.accPedalPositionArray = [NSNumber numberWithBool:true];
    }
    else if ([self.chosenVehicleData isEqualToString:@"SteeringWheelAngle"]) {
        req.steeringWheelAngle = [NSNumber numberWithBool:true];
    }
    else if ([self.chosenVehicleData isEqualToString:@"SteeringWheelAngle Array"]) {
        req.steeringWheelAngleArray = [NSNumber numberWithBool:true];
    }
    else if ([self.chosenVehicleData isEqualToString:@"Accelerometer Array"]) {
        req.accelerometerArray = [NSNumber numberWithBool:true];
    }
    else if ([self.chosenVehicleData isEqualToString:@"Gyroscope Array"]) {
        req.gyroscopeArray = [NSNumber numberWithBool:true];
    }
    else if ([self.chosenVehicleData isEqualToString:@"WheelSpeeds Array"]) {
        req.wheelSpeedsArray = [NSNumber numberWithBool:true];
    }
    else if ([self.chosenVehicleData isEqualToString:@"eCallInfo"]) {
        req.eCallInfo = [NSNumber numberWithBool:true];
    }
    else if ([self.chosenVehicleData isEqualToString:@"AirbagStatus"]) {
        req.airbagStatus = [NSNumber numberWithBool:true];
    }
    else if ([self.chosenVehicleData isEqualToString:@"EmergencyEvent"]) {
        req.emergencyEvent = [NSNumber numberWithBool:true];
    }
    else if ([self.chosenVehicleData isEqualToString:@"ClusterModeStatus"]) {
        req.clusterModeStatus = [NSNumber numberWithBool:true];
    }
    else if ([self.chosenVehicleData isEqualToString:@"MyKey"]) {
        req.myKey = [NSNumber numberWithBool:true];
    }

    [self sendAndPostRPCMessage:req];
}

- (void)sendAndPostRPCMessage:(SDLRPCRequest*)request {
    [[HSDLProxyManager manager] sendAndPostRPCMessage:request];
    [self.tabBarController setSelectedIndex:1];
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Select Vehicle Data";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[HSDLProxyManager manager] finalVehicleDataArray] count];
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell.
    cell.textLabel.text = [[[HSDLProxyManager manager] finalVehicleDataArray] objectAtIndex:indexPath.row];
    
    return cell;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"UnsubscribeVehicleData";
    vehicleDataTable.delegate = self;
    vehicleDataTable.dataSource = self;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTabel) name:@"com.sdl.notification.unsubscribeVehicleData" object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [vehicleDataTable reloadData];
}

- (void)updateTabel {
    [[[HSDLProxyManager manager] finalVehicleDataArray] removeObject:self.chosenVehicleData];
    [vehicleDataTable reloadData];
}

@end
