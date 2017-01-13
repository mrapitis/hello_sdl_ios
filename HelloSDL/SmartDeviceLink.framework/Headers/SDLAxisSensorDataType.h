//  SDLAxisSensorDataType.h
//

#import <SmartDeviceLink/SmartDeviceLink.h>
@class SDLTimeStampType;
@class SDLAxisSensorData;

@interface SDLAxisSensorDataType : SDLRPCStruct

/**
 * @abstract Constructs a new SDLAxisSensorDataType object
 */
- (instancetype)init;

/**
 * @abstract Constructs a new SDLAxisSensorDataType object indicated by the NSMutableDictionary
 * parameter
 * @param dict The dictionary to use
 */
- (instancetype)initWithDictionary:(NSMutableDictionary *)dict;

/**
 * @abstract Cumulative sum of sensor sample values.
 */
@property (strong) SDLAxisSensorData *value;

/**
 *  @abstract
 *      Timestamp in which the AccelerometerData value was recorded.
 */
@property (strong) SDLTimeStampType *timeStamp;

@end
