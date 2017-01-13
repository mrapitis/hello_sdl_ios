//  SDLAccPedalPositionType.h
//

#import <SmartDeviceLink/SmartDeviceLink.h>
@class SDLTimeStampType;

@interface SDLAccPedalPositionType : SDLRPCStruct

/**
 * @abstract Constructs a new SDLAccPedalPositionType object
 */
- (instancetype)init;

/**
 * @abstract Constructs a new SDLAccPedalPositionType object indicated by the NSMutableDictionary
 * parameter
 * @param dict The dictionary to use
 */
- (instancetype)initWithDictionary:(NSMutableDictionary *)dict;

/**
 * @abstract Accelerator pedal position (percentage depressed).
 * Float 0 - 100
 */
@property (strong) NSNumber *value;

/**
 *  @abstract
 *      Timestamp in which the accelerator pedal position was recorded.
 */
@property (strong) SDLTimeStampType *timeStamp;

@end
