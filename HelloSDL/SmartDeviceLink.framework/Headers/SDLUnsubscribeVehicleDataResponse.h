//  SDLUnsubscribeVehicleDataResponse.h
//

#import "SDLRPCResponse.h"

@class SDLVehicleDataResult;


/**
 * Unsubscribe Vehicle Data Response is sent, when UnsubscribeVehicleData has been called
 *
 * @since SmartDeviceLink 2.0
 */
@interface SDLUnsubscribeVehicleDataResponse : SDLRPCResponse {
}

/**
 * @abstract Constructs a new SDLUnsubscribeVehicleDataResponse object
 */
- (instancetype)init;

/**
 * @abstract Constructs a new SDLUnsubscribeVehicleDataResponse object indicated by the NSMutableDictionary
 * parameter
 * @param dict The dictionary to use
 */
- (instancetype)initWithDictionary:(NSMutableDictionary *)dict;

/**
 * @abstract A SDLVehicleDataResult* value. See GPSData.
 */
@property (strong) SDLVehicleDataResult *gps;

/**
 * @abstract An array of SDLVehicleDataResult* value. See SDLGPSDataType.
 */
@property (strong) SDLVehicleDataResult *gpsArray;

/**
 * @abstract A SDLVehicleDataResult* value. The vehicle speed in kilometers per hour.
 */
@property (strong) SDLVehicleDataResult *speed;

/**
 * @abstract An array of SDLVehicleDataResult* value. The vehicle speed in kilometers per hour.
 */
@property (strong) SDLVehicleDataResult *speedArray;

/**
 * @abstract A SDLVehicleDataResult* value. The number of revolutions per minute of the engine.
 */
@property (strong) SDLVehicleDataResult *rpm;

/**
 * @abstract An array of SDLVehicleDataResult* value. The number of revolutions per minute of the engine.
 */
@property (strong) SDLVehicleDataResult *rpmArray;

/**
 * @abstract A SDLVehicleDataResult* value. The fuel level in the tank (percentage)
 */
@property (strong) SDLVehicleDataResult *fuelLevel;

/**
 * @abstract An array of SDLVehicleDataResult* value. The fuel level in the tank (percentage)
 */
@property (strong) SDLVehicleDataResult *fuelLevelArray;

/**
 * @abstract A SDLVehicleDataResult* value. The fuel level state.
 */
@property (strong) SDLVehicleDataResult *fuelLevel_State;

/**
 * @abstract A SDLVehicleDataResult* value. The fuel level state.
 */
@property (strong) SDLVehicleDataResult *fuelLevel_StateArray;

/**
 * @abstract A SDLVehicleDataResult* value. The instantaneous fuel consumption in microlitres.
 */
@property (strong) SDLVehicleDataResult *instantFuelConsumption;

/**
 * @abstract A SDLVehicleDataResult* value. The external temperature in degrees celsius.
 */
@property (strong) SDLVehicleDataResult *externalTemperature;

/**
 * @abstract An array of SDLVehicleDataResult* value. The external temperature in degrees celsius.
 */
@property (strong) SDLVehicleDataResult *externalTemperatureArray;

/**
 * @abstract A SDLVehicleDataResult* value. See PRNDL.
 */
@property (strong) SDLVehicleDataResult *prndl;

/**
 * @abstract An array of SDLVehicleDataResult* value. See PRNDL.
 */
@property (strong) SDLVehicleDataResult *prndlArray;

/**
 * @abstract A SDLVehicleDataResult* value. See TireStatus.
 */
@property (strong) SDLVehicleDataResult *tirePressure;

/**
 * @abstract An array of SDLVehicleDataResult* value. See TireStatus.
 */
@property (strong) SDLVehicleDataResult *tirePressureArray;

/**
 * @abstract A SDLVehicleDataResult* value. Odometer in km.
 */
@property (strong) SDLVehicleDataResult *odometer;

/**
 * @abstract A SDLVehicleDataResult* value. The status of the seat belts.
 */
@property (strong) SDLVehicleDataResult *beltStatus;

/**
 * @abstract A SDLVehicleDataResult* value. The body information including power modes.
 */
@property (strong) SDLVehicleDataResult *bodyInformation;

/**
 * @abstract A SDLVehicleDataResult* value. The device status including signal and battery strength.
 */
@property (strong) SDLVehicleDataResult *deviceStatus;

/**
 * @abstract A SDLVehicleDataResult* value. The status of the brake pedal.
 */
@property (strong) SDLVehicleDataResult *driverBraking;

/**
 * @abstract An array of SDLVehicleDataResult* value. The status of vehicle's remaining range.
 */
@property (strong) SDLVehicleDataResult *fuelRemainingRangeArray;

/**
 * @abstract An array of SDLVehicleDataResult* value. The status of brake pedal position (percentage depressed).
 */
@property (strong) SDLVehicleDataResult *brakePedalPositionArray;

/**
 * @abstract A SDLVehicleDataResult* value. The status of the wipers.
 */
@property (strong) SDLVehicleDataResult *wiperStatus;

/**
 * @abstract A SDLVehicleDataResult* value. Status of the head lamps.
 */
@property (strong) SDLVehicleDataResult *headLampStatus;

/**
 * @abstract A SDLVehicleDataResult* value. Torque value for engine (in Nm) on non-diesel variants.
 */
@property (strong) SDLVehicleDataResult *engineTorque;

/**
 * @abstract An array of SDLVehicleDataResult* value. Torque value for engine (in Nm) on non-diesel variants.
 */
@property (strong) SDLVehicleDataResult *engineTorqueArray;
/**
 * @abstract A SDLVehicleDataResult* value. Accelerator pedal position (percentage depressed)
 */
@property (strong) SDLVehicleDataResult *accPedalPosition;

/**
 * @abstract  An array of SDLVehicleDataResult* value. Accelerator pedal position (percentage depressed)
 */
@property (strong) SDLVehicleDataResult *accPedalPositionArray;

/**
 * @abstract A SDLVehicleDataResult* value. Current angle of the steering wheel (in deg)
 */
@property (strong) SDLVehicleDataResult *steeringWheelAngle;

/**
 * @abstract An array of SDLVehicleDataResult* value. Current angle of the steering wheel (in deg)
 */
@property (strong) SDLVehicleDataResult *steeringWheelAngleArray;

/**
 * @abstract An array of SDLVehicleDataResult* value. Current accelerometer data.
 */
@property (strong) SDLVehicleDataResult *accelerometerArray;

/**
 * @abstract An array of SDLVehicleDataResult* value. Current Gyroscope data.
 */
@property (strong) SDLVehicleDataResult *gyroscopeArray;

/**
 * @abstract An array of SDLVehicleDataResult* value. Current Wheel speeds data
 */
@property (strong) SDLVehicleDataResult *wheelSpeedsArray;

@property (strong) SDLVehicleDataResult *eCallInfo;
@property (strong) SDLVehicleDataResult *airbagStatus;
@property (strong) SDLVehicleDataResult *emergencyEvent;
@property (strong) SDLVehicleDataResult *clusterModes;
@property (strong) SDLVehicleDataResult *myKey;

@end
