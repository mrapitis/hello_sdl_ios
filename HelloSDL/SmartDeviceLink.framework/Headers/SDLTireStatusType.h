//  SDLTireStatusType.h
//

#import <SmartDeviceLink/SmartDeviceLink.h>
@class SDLTireStatus;
@class SDLTimeStampType;

@interface SDLTireStatusType : SDLRPCStruct

/**
 * @abstract Constructs a new SDLTireStatusType object
 */
- (instancetype)init;

/**
 * @abstract Constructs a new SDLTireStatusType object indicated by the NSMutableDictionary
 * parameter
 * @param dict The dictionary to use
 */
- (instancetype)initWithDictionary:(NSMutableDictionary *)dict;

/**
 * @abstract Value of type "TireStatus".
 */
@property (strong) SDLTireStatus *value;

/**
 * @abstract 
 *      Timestamp in which TireStatus value was recorded.
 */
@property (strong) SDLTimeStampType *timeStamp;

@end
