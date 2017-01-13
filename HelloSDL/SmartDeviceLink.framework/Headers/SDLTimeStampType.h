//  SDLTimeStampType.h
//

#import <SmartDeviceLink/SmartDeviceLink.h>

@interface SDLTimeStampType : SDLRPCStruct

/**
 * @abstract Constructs a new SDLTireStatusType object
 */
- (instancetype)init;

/**
 * @abstract Number of seconds since the epoch.
 *
 * Integer, 0 - 4294967295
 */
- (instancetype)initWithDictionary:(NSMutableDictionary *)dict;

/**
 * @abstract Value of type "TireStatus".
 */
@property (strong) NSNumber *second;

/**
 * @abstract Number of microseconds
 * 
 * Integer, 0 - 4294967295
 */
@property (strong) NSNumber *microSecond;

@end
