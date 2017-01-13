//  SDLSteeringWheelAngleType.h
//

#import <SmartDeviceLink/SmartDeviceLink.h>
@class SDLTimeStampType;

@interface SDLSteeringWheelAngleType : SDLRPCStruct

/**
 * @abstract Constructs a new SDLSteeringWheelAngleType object
 */
- (instancetype)init;

/**
 * @abstract Constructs a new SDLSteeringWheelAngleType object indicated by the NSMutableDictionary
 * parameter
 * @param dict The dictionary to use
 */
- (instancetype)initWithDictionary:(NSMutableDictionary *)dict;

/**
 * @abstract Current angle of the steering wheel (indeg).
 * Float -2000 - 2000
 */
@property (strong) NSNumber *value;

/**
 *  @abstract
 *      Timestamp in which the steering wheel angle was recorded.
 */
@property (strong) SDLTimeStampType *timeStamp;

@end
