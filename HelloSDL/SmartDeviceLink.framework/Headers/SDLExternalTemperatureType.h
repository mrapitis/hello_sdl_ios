//  SDLExternalTemperatureType.h
//


#import <SmartDeviceLink/SmartDeviceLink.h>
@class SDLTimeStampType;

@interface SDLExternalTemperatureType : SDLRPCStruct

/**
 * @abstract Constructs a new SDLExternalTemperatureType object
 */
- (instancetype)init;

/**
 * @abstract Constructs a new SDLExternalTemperatureType object indicated by the NSMutableDictionary
 * parameter
 * @param dict The dictionary to use
 */
- (instancetype)initWithDictionary:(NSMutableDictionary *)dict;

/**
 * @abstract The external temperature in degrees celsius.
 * Float -40 - 100
 */
@property (strong) NSNumber *value;

/**
 *  @abstract
 *      Timestamp in which the external temperature was recorded.
 */
@property (strong) SDLTimeStampType *timeStamp;

@end
