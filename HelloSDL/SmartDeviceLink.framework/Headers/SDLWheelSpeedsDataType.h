//SDLWheelSpeedsDataType.h
//

#import <SmartDeviceLink/SmartDeviceLink.h>
@class SDLTimeStampType;
@class SDLWheelSpeedsData;

@interface SDLWheelSpeedsDataType : SDLRPCStruct

/**
 * @abstract Constructs a new SDLWheelSpeedsDataType object
 */
- (instancetype)init;

/**
 * @abstract Constructs a new SDLWheelSpeedsDataType object indicated by the NSMutableDictionary
 * parameter
 * @param dict The dictionary to use
 */
- (instancetype)initWithDictionary:(NSMutableDictionary *)dict;

/**
 * @abstract Value of type "SDLWheelSpeedsData".
 */
@property (strong) SDLWheelSpeedsData *value;

/**
 * @abstract
 *      Timestamp in which WheelSpeedsData value was recorded.
 */
@property (strong) SDLTimeStampType *timeStamp;

@end
