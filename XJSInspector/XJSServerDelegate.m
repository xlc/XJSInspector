//
//  XJSServerDelegate.m
//  XJSInspector
//
//  Created by Xiliang Chen on 13-11-13.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "XJSServerDelegate_Private.h"

#import <XLCUtils/XLCUtils.h>
#import "XJSBinding.h"

#import "XJSInspectorMessageProtocol.h"

@interface XJSServerDelegate ()

- (NSDictionary *)handleMessage:(NSDictionary *)message from:(NSString *)client;
- (NSDictionary *)handleScript:(NSString *)script isCommand:(BOOL)isCommand from:(NSString *)client;

@end

@implementation XJSServerDelegate
{
    BOOL _executing;
    NSMutableDictionary *_buffer;
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
        _commandContext = context;
        _buffer = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)server:(ThoMoServerStub *)theServer didReceiveData:(NSData *)theData fromClient:(NSString *)aClientIdString
{
    id obj = [NSKeyedUnarchiver unarchiveObjectWithData:theData];
    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSDictionary *reply = [self handleMessage:obj from:aClientIdString];
        if (reply) {
            [theServer send:reply toClient:aClientIdString];
        }
    } else {
        XLCFail(@"Unexpected object received: %@, from data: %@", obj, theData);
    }
}

- (void)server:(ThoMoServerStub *)theServer acceptedConnectionFromClient:(NSString *)aClientIdString
{
    XLCLogInfo(@"Connect to client: %@", aClientIdString);
}

- (void)server:(ThoMoServerStub *)theServer lostConnectionToClient:(NSString *)aClientIdString error:(NSError *)error
{
    XLCLogInfo(@"Disconnect from client: %@", aClientIdString);
    [_buffer removeObjectForKey:aClientIdString];
}

#pragma mark -

- (NSDictionary *)handleMessage:(NSDictionary *)message from:(NSString *)client
{
    NSNumber *type = message[kXJSInspectorMessageTypeKey];
    if (!type) {
        XLCFail(@"Unexpected object received: %@", message);
        return nil;
    }
    
    id iden = message[kXJSInspectorMessageIDKey];
    
    NSDictionary *reply;
    
    switch ([type unsignedIntegerValue]) {
        case XJSInspectorMessageTypeJavascript:
            reply = [self handleScript:message[kXJSInspectorMessageStringKey] isCommand:NO from:client];
            break;
            
        case XJSInspectorMessageTypeCommand:
            reply = [self handleScript:message[kXJSInspectorMessageStringKey] isCommand:YES from:client];
            break;
            
        default:
            XLCFail(@"Unexpected object received: %@", message);
            return nil;
    }
    
    if (iden) {
        NSMutableDictionary *dict = [reply mutableCopy];
        dict[kXJSInspectorMessageIDKey] = iden;
        reply = dict;
    }
    
    return reply;
}

- (NSDictionary *)handleScript:(NSString *)script isCommand:(BOOL)isCommand from:(NSString *)client
{
    NSMutableString *strbuf = _buffer[client];
    if (strbuf) {
        [strbuf appendString:script];
        [strbuf appendString:@"\n"];
        script = strbuf;
    }
    
    XJSContext *cx = isCommand ? self.commandContext : self.context;
    
    if (![cx isStringCompilableUnit:script]) {
        if (!strbuf) {
            _buffer[client] = [script mutableCopy];
        }
        return @{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeIncompletedScript) };
    }
    
    [_buffer removeObjectForKey:client];
    
    NSError *error;
    XJSValue *val = [cx evaluateString:script error:&error];
    if (val) {
        if (!isCommand) {
            if (val.isUndefined) {
                return @{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeExecuted) };
            }
            NSString *str = val.isObject ? [val.toObject description] : [val toString];
            return @{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeExecuted),
                      kXJSInspectorMessageStringKey : str,
                      };
        } else {
            id obj = val.toObject;
            
            if (obj && ![obj isKindOfClass:[NSData class]]) {
                if ([obj conformsToProtocol:@protocol(NSCoding)]) {
                    obj = [NSKeyedArchiver archivedDataWithRootObject:obj];
                } else {
                    XLCLogWarn(@"Object returned from command cannot be archived. \nCommand: %@\n Returned object:%@", script, obj);
                }
            }
            
            if (obj) {
                return @{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeExecuted),
                          kXJSInspectorMessageDataKey : obj
                          };
            }
            return @{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeExecuted) };
        }
    }
    
    return @{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeExecuted),
              kXJSInspectorMessageErrorKey : error
              };
}

@end
