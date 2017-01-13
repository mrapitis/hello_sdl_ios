//  SDLRpmType.h
//

#import <SmartDeviceLink/SmartDeviceLink.h>
@class SDLTimeStampType;

@interface SDLRpmType : SDLRPCStruct

/**
 * @abstract Constructs a new SDLRpmType object
 */
- (instancetype)init;

/**
 * @abstract Constructs a new SDLRpmType object indicated by the NSMutableDictionary
 * parameter
 * @param dict The dictionary to use
 */
- (instancetype)initWithDictionary:(NSMutableDictionary *)dict;

/**
 * @abstract The number of revolutions per minute of the engine.
 * Integer 0 - 20000
 */
@property (strong) NSNumber *value;

/**
*  @abstract
*      Timestamp in which the RPM was recorded.
*/
@property (strong) SDLTimeStampType *timeStamp;

@end
