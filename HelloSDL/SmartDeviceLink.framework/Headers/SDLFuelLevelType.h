//  SDLFuelLevelType.h
//


#import <SmartDeviceLink/SmartDeviceLink.h>
@class SDLTimeStampType;

@interface SDLFuelLevelType : SDLRPCStruct

/**
 * @abstract Constructs a new SDLFuelLevelType object
 */
- (instancetype)init;

/**
 * @abstract Constructs a new SDLFuelLevelType object indicated by the NSMutableDictionary
 * parameter
 * @param dict The dictionary to use
 */
- (instancetype)initWithDictionary:(NSMutableDictionary *)dict;

/**
 * @abstract The fuel level in the tank (percentage).
 * Float -6 - 106
 */
@property (strong) NSNumber *value;

/**
 *  @abstract
 *      Timestamp in which the fuel level was recorded.
 */
@property (strong) SDLTimeStampType *timeStamp;

@end
