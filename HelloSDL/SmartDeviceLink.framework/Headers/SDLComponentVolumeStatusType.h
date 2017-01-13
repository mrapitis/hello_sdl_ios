//  SDLComponentVolumeStatusType.h
//

#import <SmartDeviceLink/SmartDeviceLink.h>
@class SDLComponentVolumeStatus;
@class SDLTimeStampType;

@interface SDLComponentVolumeStatusType : SDLRPCStruct

/**
 * @abstract Constructs a new SDLComponentVolumeStatusType object
 */
- (instancetype)init;

/**
 * @abstract Constructs a new SDLComponentVolumeStatusType object indicated by the NSMutableDictionary
 * parameter
 * @param dict The dictionary to use
 */
- (instancetype)initWithDictionary:(NSMutableDictionary *)dict;

/**
 * @abstract Value of type "ComponentVolumeStatus".
 */
@property (strong) SDLComponentVolumeStatus *value;

/**
 *  @abstract
 *      Timestamp in which the ComponentVolumeStatus value was recorded.
 */
@property (strong) SDLTimeStampType *timeStamp;

@end
