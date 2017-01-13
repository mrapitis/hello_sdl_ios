//
//  SDLDebugTool+ObjectLogging.m
//  SyncProxyTester
//
//

#import "SDLDebugTool+ObjectLogging.h"
#import <objc/runtime.h>
//#import "XMLWriter.h"

static NSString* const BulkDataString = @"bulkData";
static NSString* const DefaultString = @"default";
static NSString* const DisplayColorTag = @"DisplayColor";
static NSString* const LogStringNotification = @"(notification)";
static NSString* const LogMessageTag = @"LogMessage";
static NSString* const LogStringResponse = @"(response)";
static NSString* const LogStringRequest = @"(request)";
static NSString* const NotificationColorCode = @"ffffff00";
static NSString* const RequestColorCode = @"ff00ffff";
static NSString* const ResponseSuccessColorCode = @"ff00ff00";
static NSString* const ResponseFailureColorCode = @"ffff0000";
static NSString* const StringColorCode = @"ffffffff";
static NSString* const StringTextTag = @"StringText";
static NSString* const StringValueTag = @"StringValue";
static NSString* const TimeStampTag = @"TimeStamp";


@interface SDLDebugTool ()

@property (nonatomic, strong) dispatch_queue_t xmlLogQueue;
+ (SDLDebugTool *)sharedTool;
- (NSDateFormatter *)logDateFormatter;

@end

@implementation SDLDebugTool (ObjectLogging)

#pragma mark - Logging

- (void)setXmlLogQueue:(dispatch_queue_t)object {
    objc_setAssociatedObject(self, @selector(xmlLogQueue), object, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (dispatch_queue_t)xmlLogQueue {
    return objc_getAssociatedObject(self, @selector(xmlLogQueue));
}

+ (void)logMessage:(id)info {
    [self logMessage:info withType:SDLDebugType_Debug toOutput:SDLDebugOutput_All toGroup:@"default"];
}

+ (void)logMessage:(id)info withType:(SDLDebugType)type {
    [self logMessage:info withType:type toOutput:SDLDebugOutput_All toGroup:DefaultString];
}

+ (void)logMessage:(id)info withType:(SDLDebugType)type toOutput:(SDLDebugOutput)output {
    [SDLDebugTool logMessage:info withType:type toOutput:output toGroup:DefaultString];
}

// The designated logInfo method. All outputs should be performed here.
+ (void)logMessage:(id)info withType:(SDLDebugType)type toOutput:(SDLDebugOutput)output toGroup:(NSString *)consoleGroupName {
    // Format the message, prepend the thread id
    NSString *outputString = [NSString stringWithFormat:@"%@", info];
    
    //  Output to the various destinations
    
    //Output To DeviceConsole
    if (output & SDLDebugOutput_DeviceConsole) {
        NSLog(@"%@", outputString);
    }
    
    //Output To DebugToolConsoles
    if (output & SDLDebugOutput_DebugToolConsole) {
        NSSet* consoleListeners = nil;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        if ([SDLDebugTool respondsToSelector:@selector(getConsoleListenersForGroup:)]) {
            consoleListeners = [SDLDebugTool performSelector:@selector(getConsoleListenersForGroup:) withObject:consoleGroupName];
        }
#pragma clang diagnostic pop
        for (NSObject<SDLDebugToolConsole> *console in consoleListeners) {
            if ([info isKindOfClass:SDLRPCMessage.class]) {
                if ([console respondsToSelector:@selector(logMessage:)]) {
                    [console performSelector:@selector(logMessage:) withObject:info];
                }
            } else {
                [console logInfo:outputString];
            }
        }
    }
    
    //Output To LogFile
    if (output & SDLDebugOutput_File) {
        [SDLDebugTool writeToLogFile:outputString];
    }
    
    //Output To Siphon
    [SDLSiphonServer init];
    [SDLSiphonServer _siphonNSLogData:outputString];
}

#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"   // to suppress the compilation warning
+ (void)logInfo:(NSString *)info withType:(SDLDebugType)type toOutput:(SDLDebugOutput)output toGroup:(NSString *)consoleGroupName {
    if (([info rangeOfString:LogStringRequest].location == NSNotFound)&&([info rangeOfString:LogStringResponse].location == NSNotFound)&&([info rangeOfString:LogStringNotification].location == NSNotFound)) {
        [self logMessage:info withType:type toOutput:output toGroup:consoleGroupName];
    }
}
@end
