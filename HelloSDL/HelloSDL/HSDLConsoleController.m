//
//  HSDLConsoleController.m
//  HelloSDL
//
//  Created by CHDSEZ318988DADM on 10/01/17.
//  Copyright © 2017 Ford. All rights reserved.
//

#import "HSDLConsoleController.h"
// PropertyUtil.m
#import "objc/runtime.h"

NSString* const GetterButtonTitle = @"Get Getter Methods";

@interface HSDLConsoleController () {
    id rpcMessage;
}
@end

@implementation HSDLConsoleController

#pragma mark Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    NSDictionary *currentDictionary = [messageList objectAtIndex:indexPath.row];
    id msg = [currentDictionary objectForKey:@"object"];
    
    NSString *tempdetail = [@"Time: " stringByAppendingString:[dateFormatter stringFromDate:[currentDictionary objectForKey:@"date"]]];
    
    if ([msg isKindOfClass:SDLRPCMessage.class]) {
        rpcMessage = (SDLRPCMessage*) msg;
        NSString* title = [NSString stringWithFormat:@"%@ (%@)", [rpcMessage name], [rpcMessage messageType]];
        cell.textLabel.text = title;
        
        if ([[rpcMessage messageType] isEqualToString:@"response"]) {
            SDLRPCResponse* response = (SDLRPCResponse*) rpcMessage;
            
            NSString* detail = [NSString stringWithFormat:@"%@ - %@", tempdetail, [response resultCode]];
            cell.detailTextLabel.text = detail;
        } else {
            cell.detailTextLabel.text = tempdetail;
        }
        
    } else {
        cell.textLabel.text = msg;
        cell.detailTextLabel.text = tempdetail;
    }
    
    return cell;
}

#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *currentDictionary = [messageList objectAtIndex:indexPath.row];
    id obj = [currentDictionary objectForKey:@"object"];
    NSString* alertText = nil;
    UIAlertController *alert = [UIAlertController
                                    alertControllerWithTitle:@"RPCMessage"
                                    message:alertText
                                    preferredStyle:UIAlertControllerStyleAlert];
    if ([obj isKindOfClass:SDLRPCMessage.class]) {
        rpcMessage = obj;
        NSDictionary* dictionary = [rpcMessage serializeAsDictionary:2];
        if ([dictionary valueForKey:@"bulkData"]) {
            NSData *data = [dictionary valueForKey:@"bulkData"] ;
            NSString *testString = [data base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
            [dictionary setValue:testString forKey:@"bulkData"];
        }
        NSError *error = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:&error];
        
        if (!jsonData) {
            alertText = @"Error parsing the JSON.";
        } else {
            alertText = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
        UIAlertAction *getterButtonTitle = [UIAlertAction actionWithTitle:@"GetterButtonTitle" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
            UIAlertController *showAlert = [UIAlertController
                                        alertControllerWithTitle:@"RPCMessage"
                                        message:[self allPropertyNamesForObject:rpcMessage]
                                        preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
            }];
            [showAlert addAction:okAction];
            [self presentViewController:showAlert animated:YES completion:nil];
        }];
        [alert addAction:getterButtonTitle];
    } else {
        alertText = [NSString stringWithFormat:@"%@",[obj description]];
    }
    [alert setMessage:alertText];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}


- (NSString *)allPropertyNamesForObject:(id) object {
    unsigned count;
    NSMutableString *finalString = [NSMutableString string];
    Class class = [object class];
    while(class != [NSObject class]) {
        objc_property_t *properties = class_copyPropertyList(class, &count);
        for (unsigned i = 0; i < count; i++) {
            objc_property_t property = properties[i];
            NSString *propertyName = [NSString stringWithUTF8String:property_getName(property)];
            if ([propertyName isEqualToString:@"bulkData"]) {
                if ([object valueForKey:@"bulkData"]) {
                    [finalString appendString:[NSString stringWithFormat:@"%@ \n",[[object valueForKey:@"bulkData"] subdataWithRange:NSMakeRange(0, 5)]]];
                }
            } else {
                if ([[object valueForKey:propertyName] isKindOfClass:[SDLRPCStruct class]]) {
                    [finalString appendString:[NSString stringWithFormat:@"%@ \n",[propertyName uppercaseString]]];
                    [finalString appendString:[NSString stringWithFormat:@"%@ \n",[self allPropertyNamesForObject:[object valueForKey:propertyName]]]];
                } else if ([[object valueForKey:propertyName] isKindOfClass:[NSArray class]] || [[object valueForKey:propertyName] isKindOfClass:[NSDictionary class]]) {
                    for (id object1 in [object valueForKey:propertyName]) {
                        if ([object1 isKindOfClass:[SDLRPCStruct class]]) {
                            [finalString appendString:[NSString stringWithFormat:@"%@ \n",[propertyName uppercaseString]]];
                            [finalString appendString:[NSString stringWithFormat:@"%@ \n",[self allPropertyNamesForObject:object1]]];
                        } else {
                            [finalString appendString:[NSString stringWithFormat:@"%@ : %@ \n",propertyName,[object valueForKey:propertyName]]];
                            break;
                        }
                    }
                } else {
                    [finalString appendString:[NSString stringWithFormat:@"%@ : %@ \n",propertyName,[object valueForKey:propertyName]]];
                }
            }
        }
        free(properties);
        class = class_getSuperclass([class class]);
    }
    return finalString;
}

-(void)showMessage:(NSString*)message withTitle:(NSString *)title {
    
    UIAlertController * alert=   [UIAlertController
                                  alertControllerWithTitle:title
                                  message:message
                                  preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
        
        //do something when click button
    }];
    [alert addAction:okAction];
    UIViewController *vc = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    [vc presentViewController:alert animated:YES completion:nil];
}

@end
