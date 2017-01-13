//  SDLVehicleDataEventStatusType.h
//

#import <SmartDeviceLink/SmartDeviceLink.h>
@class SDLVehicleDataEventStatus;
@class SDLTimeStampType;

@interface SDLVehicleDataEventStatusType : SDLRPCStruct

/**
 * @abstract Constructs a new SDLVehicleDataEventStatusType object
 */
- (instancetype)init;

/**
 * @abstract Constructs a new SDLVehicleDataEventStatusType object indicated by the NSMutableDictionary
 * parameter
 * @param dict The dictionary to use
 */
- (instancetype)initWithDictionary:(NSMutableDictionary *)dict;

/**
 * @abstract Value of type "VehicleDataEventStatus".
 */
@property (strong) SDLVehicleDataEventStatus *value;

/**
 * @abstract
 *      Timestamp in which VehicleDataEventStatus value was recorded.
 */
@property (strong) SDLTimeStampType *timeStamp;

@end
