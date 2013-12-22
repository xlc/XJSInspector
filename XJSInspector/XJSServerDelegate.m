//
//  XJSServerDelegate.m
//  XJSInspector
//
//  Created by Xiliang Chen on 13-11-13.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "XJSServerDelegate_Private.h"

#import "XLCAssertion.h"
#import "XJSBinding.h"

#import "XJSInspectorMessageProtocol.h"

@interface XJSServerDelegate ()

- (NSDictionary *)handleMessage:(NSDictionary *)message;
- (NSDictionary *)handleScript:(NSString *)script returnString:(BOOL)returnStr;

@end

@implementation XJSServerDelegate
{
    BOOL _executing;
}

- (id)init
{
    return [self initWithContext:[[XJSContext alloc] init]];
}

- (id)initWithContext:(XJSContext *)context
{
    self = [super init];
    if (self) {
        _context = context;
    }
    return self;
}

- (void)server:(ThoMoServerStub *)theServer didReceiveData:(NSData *)theData fromClient:(NSString *)aClientIdString
{
    id obj = [NSKeyedUnarchiver unarchiveObjectWithData:theData];
    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSDictionary *reply = [self handleMessage:obj];
        if (reply) {
            [theServer send:reply toClient:aClientIdString];
        }
    } else {
        XFAIL(@"Unexpected object received: %@, from data: %@", obj, theData);
    }
}

- (void)server:(ThoMoServerStub *)theServer acceptedConnectionFromClient:(NSString *)aClientIdString
{
    XILOG(@"Connect to client: %@", aClientIdString);
}

- (void)server:(ThoMoServerStub *)theServer lostConnectionToClient:(NSString *)aClientIdString error:(NSError *)error
{
    XILOG(@"Disconnect from client: %@", aClientIdString);
}

#pragma mark -

- (NSDictionary *)handleMessage:(NSDictionary *)message
{
    NSNumber *type = message[kXJSInspectorMessageTypeKey];
    if (!type) {
        XFAIL(@"Unexpected object received: %@", message);
        return nil;
    }
    
    id iden = message[kXJSInspectorMessageIDKey];
    
    NSDictionary *reply;
    
    switch ([type unsignedIntegerValue]) {
        case XJSInspectorMessageTypeJavascript:
            reply = [self handleScript:message[kXJSInspectorMessageStringKey] returnString:YES];
            break;
            
        case XJSInspectorMessageTypeCommand:
            reply = [self handleScript:message[kXJSInspectorMessageStringKey] returnString:NO];
            break;
            
        default:
            XFAIL(@"Unexpected object received: %@", message);
            return nil;
    }
    
    if (iden) {
        NSMutableDictionary *dict = [reply mutableCopy];
        dict[kXJSInspectorMessageIDKey] = iden;
        reply = dict;
    }
    
    return reply;
}

- (NSDictionary *)handleScript:(NSString *)script returnString:(BOOL)returnStr
{
    if (![script length]) {
        return nil;
    }
    
    if (![_context isStringCompilableUnit:script]) {
        return @{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeIncompletedScript) };
    }
    
    NSError *error;
    XJSValue *val = [_context evaluateString:script error:&error];
    if (val) {
        if (returnStr) {
            return @{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeExecuted),
                      kXJSInspectorMessageStringKey :val.toString
                      };
        } else {
            id obj = val.toObject;
            
            if (![obj isKindOfClass:[NSData class]]) {
                if ([obj conformsToProtocol:@protocol(NSCoding)]) {
                    obj = [NSKeyedArchiver archivedDataWithRootObject:obj];
                } else {
                    XWLOG(@"Object returned from command cannotbe archived. \nCommand: %@\n Returned object:%@", script, obj);
                    obj = [NSNull null];
                }
            }
            
            if (!obj) {
                obj = [NSNull null];
            }
            
            return @{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeExecuted),
                      kXJSInspectorMessageDataKey : obj
                      };
        }
    }
    
    return @{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeExecuted),
              kXJSInspectorMessageErrorKey : error
              };
}

@end
