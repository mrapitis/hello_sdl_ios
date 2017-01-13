//
//  SDLDebugTool+ObjectLogging.h
//  SyncProxyTester
//
//  Created by CHDSEZ318988DADM on 21/06/16.
//
//

#import "HSDLProxyManager.h"

@interface SDLDebugTool (ObjectLogging)

+ (void)logMessage:(id)info;
+ (void)logMessage:(id)info withType:(SDLDebugType)type;
+ (void)logMessage:(id)info withType:(SDLDebugType)type toOutput:(SDLDebugOutput)output;
+ (void)logMessage:(id)info withType:(SDLDebugType)type toOutput:(SDLDebugOutput)output toGroup:(NSString *)consoleGroupName;

+ (void)enableXMLLogFile;
+ (void)disableXMLLogFile;
+ (void)writeToXMLFile:(id)info;

@end
