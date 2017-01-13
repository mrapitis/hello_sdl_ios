 //  SDLAxisSensorData.h
//

#import <SmartDeviceLink/SmartDeviceLink.h>

@interface SDLAxisSensorData : SDLRPCStruct

/**
 * @abstract Constructs a new SDLAxisSensorData object
 */
- (instancetype)init;

/**
 * @abstract Constructs a new SDLAxisSensorData object indicated by the NSMutableDictionary
 * parameter
 * @param dict The dictionary to use
 */
- (instancetype)initWithDictionary:(NSMutableDictionary *)dict;

/**
 * @abstract Cumulative sum #0 of sensor sample values.
 * Interger
 */
@property (strong) NSNumber *cumulativeValue0;

/**
 * @abstract Cumulative sum #1 of sensor sample values.
 * Interger
 */
@property (strong) NSNumber *cumulativeValue1;

/**
 * @abstract Cumulative sum #2 of sensor sample values.
 * Interger
 */
@property (strong) NSNumber *cumulativeValue2;

@end
