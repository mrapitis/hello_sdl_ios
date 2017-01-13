//  SDLOnVehicleData.h
//

#import "SDLRPCNotification.h"

@class SDLAccPedalPositionType;
@class SDLAirbagStatus;
@class SDLAxisSensorDataType;
@class SDLBeltStatus;
@class SDLBodyInformation;
@class SDLBrakePedalPositionType;
@class SDLClusterModeStatus;
@class SDLComponentVolumeStatus;
@class SDLComponentVolumeStatusType;
@class SDLDeviceStatus;
@class SDLECallInfo;
@class SDLEmergencyEvent;
@class SDLEngineTorqueType;
@class SDLExternalTemperatureType;
@class SDLFuelLevelType;
@class SDLFuelRemainingRangeType;
@class SDLGPSData;
@class SDLGPSDataType;
@class SDLHeadLampStatus;
@class SDLMyKey;
@class SDLPRNDL;
@class SDLPRNDLType;
@class SDLRpmType;
@class SDLSpeedType;
@class SDLSteeringWheelAngleType;
@class SDLTireStatus;
@class SDLTireStatusType;
@class SDLVehicleDataEventStatus;
@class SDLWiperStatus;
@class SDLWheelSpeedsDataType;


/**
 * Request vehicle data.
 *
 * Since SmartDeviceLink 2.0
 */
@interface SDLOnVehicleData : SDLRPCNotification {
}


/**
 * @abstract Constructs a new SDLOnVehicleData object
 */
- (instancetype)init;

/**
 * @abstract Constructs a new SDLOnVehicleData object indicated by the NSMutableDictionary
 * parameter
 * @param dict The dictionary to use
 */
- (instancetype)initWithDictionary:(NSMutableDictionary *)dict;

/**
 * @abstract A SDLGPSData* value. See GPSData.
 */
@property (strong) SDLGPSData *gps;


/**
 * @abstract A SDLGPSDataType* value. 
 * See SDLGPSDataType.
 */
@property (strong) NSMutableArray <SDLGPSDataType*> *gpsArray;

/**
 * @abstract The vehicle speed in kilometers per hour.
 */
@property (strong) NSNumber *speed;

/**
 * @abstract An array of the vehicle speed in kilometers per hour.
 */
@property (strong) NSMutableArray <SDLSpeedType *> *speedArray;

/**
 * @abstract The number of revolutions per minute of the engine.
 */
@property (strong) NSNumber *rpm;

/**
 * @abstract An array of the number of revolutions per minute of
 * the engine.
 */
@property (strong) NSMutableArray <SDLRpmType *> *rpmArray;

/**
 * @abstract The fuel level in the tank (percentage)
 */
@property (strong) NSNumber *fuelLevel;

/**
 * @abstract An array of the fuel level in the tank (percentage)
 */
@property (strong) NSMutableArray <SDLFuelLevelType *> *fuelLevelArray;

/**
 * @abstract A SDLComponentVolumeStatus* value. The fuel level state.
 */
@property (strong) SDLComponentVolumeStatus *fuelLevel_State;

/**
 * @abstract An array of the fuel level state.
 */
@property (strong) NSMutableArray <SDLComponentVolumeStatusType *> *fuelLevel_StateArray;

/**
 * @abstract The instantaneous fuel consumption in microlitres.
 */
@property (strong) NSNumber *instantFuelConsumption;

/**
 * @abstract The external temperature in degrees celsius.
 */
@property (strong) NSNumber *externalTemperature;

/**
 * @abstract An array of the external temperature in degrees celsius.
 */
@property (strong) NSMutableArray <SDLExternalTemperatureType *> *externalTemperatureArray;

/**
 * @abstract The Vehicle Identification Number
 */
@property (strong) NSString *vin;

/**
 * @abstract See PRNDL.
 */
@property (strong) SDLPRNDL *prndl;

/**
 * @abstract See PRNDLType.
 */
@property (strong) NSMutableArray <SDLPRNDLType *> *prndlArray;

/**
 * @abstract A SDLTireStatus* value. See TireStatus.
 */
@property (strong) SDLTireStatus *tirePressure;

/**
 * @abstract A SDLTireStatusType* value. See TireStatusType.
 */
@property (strong) NSMutableArray <SDLTireStatusType *> *tirePressureArray;

/**
 * @abstract Odometer reading in km.
 */
@property (strong) NSNumber *odometer;

/**
 * @abstract A SDLBeltStatus* value. The status of the seat belts.
 */
@property (strong) SDLBeltStatus *beltStatus;

/**
 * @abstract A SDLBodyInformation* value. The body information including power modes.
 */
@property (strong) SDLBodyInformation *bodyInformation;

/**
 * @abstract A SDLDeviceStatus* value. The device status including signal and battery strength.
 */
@property (strong) SDLDeviceStatus *deviceStatus;

/**
 * @abstract A SDLVehicleDataResult* value. The status of the brake pedal.
 */
@property (strong) SDLVehicleDataEventStatus *driverBraking;

 /**
 * @abstract A SDLFuelRemainingRangeType* value. An array of vehicle's remaining range.
 */
@property (strong) NSMutableArray <SDLFuelRemainingRangeType *> *fuelRemainingRangeArray;

/**
 * @abstract A SDLBrakePedalPositionType* value. An array of brake pedal position (percentage depressed).
 */
@property (strong) NSMutableArray <SDLBrakePedalPositionType *> *brakePedalPositionArray;

/**
 * @abstract A SDLWiperStatus* value. The status of the wipers.
 */
@property (strong) SDLWiperStatus *wiperStatus;

/**
 * @abstract A SDLHeadLampStatus* value. Status of the head lamps.
 */
@property (strong) SDLHeadLampStatus *headLampStatus;

/**
 * @abstract Torque value for engine (in Nm) on non-diesel variants.
 */
@property (strong) NSNumber *engineTorque;

/**
 * @abstract An array of torque values for engine (in Nm) on non-diesel variants.
 */
@property (strong) NSMutableArray <SDLEngineTorqueType *> *engineTorqueArray;

/**
 * @abstract Accelerator pedal position (percentage depressed)
 */
@property (strong) NSNumber *accPedalPosition;

/**
 * @abstract An array of accelerator pedal position (percentage depressed)
 */
@property (strong) NSMutableArray <SDLAccPedalPositionType *> *accPedalPositionArray;

/**
 * @abstract Current angle of the steering wheel (in deg)
 */
@property (strong) NSNumber *steeringWheelAngle;

/**
 * @abstract An array of the angle of the steering wheel (in deg)
 */
@property (strong) NSMutableArray <SDLSteeringWheelAngleType *> *steeringWheelAngleArray;

/**
 * @abstract An array of accelerometer data.
 */
@property (strong) NSMutableArray <SDLAxisSensorDataType *> *accelerometerArray;

/**
 * @abstract An array of Gyroscope data
 */
@property (strong) NSMutableArray <SDLAxisSensorDataType *> *gyroscopeArray;

/**
 * @abstract An array of Wheel speeds data
 */
@property (strong) NSMutableArray <SDLWheelSpeedsDataType *> *wheelSpeedsArray;

@property (strong) SDLECallInfo *eCallInfo;
@property (strong) SDLAirbagStatus *airbagStatus;
@property (strong) SDLEmergencyEvent *emergencyEvent;
@property (strong) SDLClusterModeStatus *clusterModeStatus;
@property (strong) SDLMyKey *myKey;


@end
