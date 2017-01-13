//  SDLEngineTorqueType.h
//


#import <SmartDeviceLink/SmartDeviceLink.h>
@class SDLTimeStampType;

@interface SDLEngineTorqueType : SDLRPCStruct

/**
 * @abstract Constructs a new SDLEngineTorqueType object
 */
- (instancetype)init;

/**
 * @abstract Constructs a new SDLEngineTorqueType object indicated by the NSMutableDictionary
 * parameter
 * @param dict The dictionary to use
 */
- (instancetype)initWithDictionary:(NSMutableDictionary *)dict;

/**
 * @abstract Torque value for engine (in Nm) on non-diesel variants
 * Float -1000 - 2000
 */
@property (strong) NSNumber *value;

/**
 *  @abstract
 *      Timestamp in which the engine torque was recorded.
 */
@property (strong) SDLTimeStampType *timeStamp;

@end
