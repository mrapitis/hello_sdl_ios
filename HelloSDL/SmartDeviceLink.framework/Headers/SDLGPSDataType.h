//  SDLGPSDataType.h
//

#import <SmartDeviceLink/SmartDeviceLink.h>
@class SDLGPSData;
@class SDLTimeStampType;

@interface SDLGPSDataType : SDLRPCStruct

/**
 * @abstract Constructs a new SDLGPSDataType object
 */
- (instancetype)init;

/**
 * @abstract Constructs a new SDLGPSDataType object indicated by the NSMutableDictionary
 * parameter
 * @param dict The dictionary to use
 */
- (instancetype)initWithDictionary:(NSMutableDictionary *)dict;

/**
 * @abstract Value of type "GPSData".
 */
@property (strong) SDLGPSData *value;

/**
 *  @abstract
 *      Timestamp in which the GPSData value was recorded.
 */
@property (strong) SDLTimeStampType *timeStamp;

@end
