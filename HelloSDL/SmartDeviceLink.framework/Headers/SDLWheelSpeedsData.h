//  SDLWheelSpeedsData.h
//

#import <SmartDeviceLink/SmartDeviceLink.h>

@interface SDLWheelSpeedsData : SDLRPCStruct

/**
 * @abstract Constructs a new SDLWheelSpeedsData object
 */
- (instancetype)init;

/**
 * @abstract Constructs a new SDLWheelSpeedsData object indicated by the NSMutableDictionary
 * parameter
 * @param dict The dictionary to use
 */
- (instancetype)initWithDictionary:(NSMutableDictionary *)dict;

/**
 * @abstract Front right wheel rotation count.
 * Interger
 */
@property (strong) NSNumber *whlRotatFr_No_Cnt;

/**
 * @abstract Front left wheel rotation count.
 * Interger
 */
@property (strong) NSNumber *whlRotatFl_No_Cnt;

/**
 * @abstract Rear right wheel rotation count.
 * Interger
 */
@property (strong) NSNumber *whlRotatRr_No_Cnt;

/**
 * @abstract Rear left wheel rotation count.
 * Interger
 */
@property (strong) NSNumber *whlRotatRl_No_Cnt;

/**
 * @abstract Front left wheel direction.
 * Interger
 */
@property (strong) NSNumber *whlDirFr_D_Actl;

/**
 * @abstract Front left wheel direction.
 * Interger
 */
@property (strong) NSNumber *whlDirFl_D_Actl;

/**
 * @abstract Rear right wheel direction.
 * Interger
 */
@property (strong) NSNumber *whlDirRr_D_Actl;

/**
 * @abstract Rear left wheel direction.
 * Interger
 */
@property (strong) NSNumber *whlDirRl_D_Actl;
@end
