//  SDLSpeedType.h
//

#import <SmartDeviceLink/SmartDeviceLink.h>
@class SDLTimeStampType;

@interface SDLSpeedType : SDLRPCStruct

/**
 * @abstract Constructs a new SDLSpeedType object
 */
- (instancetype)init;

/**
 * @abstract Constructs a new SDLSpeedType object indicated by the NSMutableDictionary
 * parameter
 * @param dict The dictionary to use
 */
- (instancetype)initWithDictionary:(NSMutableDictionary *)dict;

/**
 * @abstract Vehicle speed in kilometers per hour.
 * Float 0 - 700
 */
@property (strong) NSNumber *value;

/**
 *  @abstract
 *      Timestamp in which the speed was recorded.
 */
@property (strong) SDLTimeStampType *timeStamp;

@end
