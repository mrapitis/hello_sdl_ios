//  GetVehicleDataViewController.m
//  SyncProxyTester
//  Copyright (c) 2013 Ford Motor Company. All rights reserved.

#import "GetVehicleDataViewController.h"
#import "HSDLProxyManager.h"

@interface GetVehicleDataViewController () <UITableViewDataSource, UITableViewDelegate> {
    NSMutableArray *vehicleDataList;
    IBOutlet UITableView *vehicleDataTable;
}

@end

@implementation GetVehicleDataViewController

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    NSString *chosenVehicleData =  cell.textLabel.text;
    
    SDLGetVehicleData *req = [[SDLGetVehicleData alloc] init];
    
    if ([chosenVehicleData isEqualToString:@"GPS"]) {
        req.gps = [NSNumber numberWithBool:true];
    }
    else if ([chosenVehicleData isEqualToString:@"Speed"]) {
        req.speed = [NSNumber numberWithBool:true];
    }
    else if ([chosenVehicleData isEqualToString:@"RPM"]) {
        req.rpm = [NSNumber numberWithBool:true];
    }
    else if ([chosenVehicleData isEqualToString:@"FuelLevel"]) {
        req.fuelLevel = [NSNumber numberWithBool:true];
    }
    else if ([chosenVehicleData isEqualToString:@"FuelLevelState"]) {
        req.fuelLevel_State = [NSNumber numberWithBool:true];
    }
    else if ([chosenVehicleData isEqualToString:@"InstantFuelConsuption"]) {
        req.instantFuelConsumption = [NSNumber numberWithBool:true];
    }
    else if ([chosenVehicleData isEqualToString:@"ExternalTemperature"]) {
        req.externalTemperature = [NSNumber numberWithBool:true];
    }
    else if ([chosenVehicleData isEqualToString:@"VIN"]) {
        req.vin = [NSNumber numberWithBool:true];
    }
    else if ([chosenVehicleData isEqualToString:@"PRNDL"]) {
        req.prndl = [NSNumber numberWithBool:true];
    }
    else if ([chosenVehicleData isEqualToString:@"TirePressure"]) {
        req.tirePressure = [NSNumber numberWithBool:true];
    }
    else if ([chosenVehicleData isEqualToString:@"Odometer"]) {
        req.odometer = [NSNumber numberWithBool:true];
    }
    else if ([chosenVehicleData isEqualToString:@"BeltStatus"]) {
        req.beltStatus = [NSNumber numberWithBool:true];
    }
    else if ([chosenVehicleData isEqualToString:@"BodyInformation"]) {
        req.bodyInformation = [NSNumber numberWithBool:true];
    }
    else if ([chosenVehicleData isEqualToString:@"DeviceStatus"]) {
        req.deviceStatus = [NSNumber numberWithBool:true];
    }
    else if ([chosenVehicleData isEqualToString:@"DriverBraking"]) {
        req.driverBraking = [NSNumber numberWithBool:true];
    }
    else if ([chosenVehicleData isEqualToString:@"WiperStatus"]) {
        req.wiperStatus = [NSNumber numberWithBool:true];
    }
    else if ([chosenVehicleData isEqualToString:@"HeadLampStatus"]) {
        req.headLampStatus = [NSNumber numberWithBool:true];
    }
    else if ([chosenVehicleData isEqualToString:@"EngineTorque"]) {
        req.engineTorque = [NSNumber numberWithBool:true];
    }
    else if ([chosenVehicleData isEqualToString:@"AccPedalPosition"]) {
        req.accPedalPosition = [NSNumber numberWithBool:true];
    }
    else if ([chosenVehicleData isEqualToString:@"SteeringWheelAngle"]) {
        req.steeringWheelAngle = [NSNumber numberWithBool:true];
    }
    else if ([chosenVehicleData isEqualToString:@"eCallInfo"]) {
        req.eCallInfo = [NSNumber numberWithBool:true];
    }
    else if ([chosenVehicleData isEqualToString:@"AirbagStatus"]) {
        req.airbagStatus = [NSNumber numberWithBool:true];
    }
    else if ([chosenVehicleData isEqualToString:@"EmergencyEvent"]) {
        req.emergencyEvent = [NSNumber numberWithBool:true];
    }
    else if ([chosenVehicleData isEqualToString:@"ClusterModeStatus"]) {
        req.clusterModeStatus = [NSNumber numberWithBool:true];
    }
    else if ([chosenVehicleData isEqualToString:@"MyKey"]) {
        req.myKey = [NSNumber numberWithBool:true];
    }
    
    req.correlationID = [[HSDLProxyManager manager] hsdl_getNextCorrelationId];
   
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
    return vehicleDataList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) { 
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier]; 
    } 
    
    // Configure the cell. 
    cell.textLabel.text = [vehicleDataList objectAtIndex:indexPath.row]; 
    
    return cell;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"GetVehicleData";
    vehicleDataTable.delegate = self;
    vehicleDataTable.dataSource = self;
    
    vehicleDataList = [[NSMutableArray alloc] initWithObjects:
                       @"GPS",
                       @"Speed",
                       @"RPM",
                       @"FuelLevel",
                       @"FuelLevelState",
                       @"FuelRange",
                       @"InstantFuelConsumption",
                       @"ExternalTemperature",
                       @"VIN",
                       @"PRNDL",
                       @"TirePressure",
                       @"TirePressureValue",
                       @"TPMS",
                       @"TurnSignal",
                       @"Odometer",
                       @"BeltStatus",
                       @"BodyInformation",
                       @"DeviceStatus",
                       @"DriverBraking",
                       @"WiperStatus",
                       @"HeadLampStatus",
                       @"EngineTorque",
                       @"AccPedalPosition",
                       @"ABSState",
                       @"SteeringWheelAngle",
                       @"eCallInfo",
                       @"AirbagStatus",
                       @"EmergencyEvent",
                       @"ClusterModeStatus",
                       @"MyKey",
                       nil];
}

@end
