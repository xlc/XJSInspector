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
- (NSDictionary *)handleScript:(NSString *)script;

@end

@implementation XJSServerDelegate
{
    NSMutableString *_buffer;
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
        _buffer = [NSMutableString string];
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
    
    switch ([type unsignedIntegerValue]) {
        case XJSInspectorMessageTypeJavascript:
            return [self handleScript:message[kXJSInspectorMessageStringKey]];
            
        default:
            XFAIL(@"Unexpected object received: %@", message);
            return nil;
    }
}

- (NSDictionary *)handleScript:(NSString *)script
{
    if (![script length]) {
        return nil;
    }
    
    [_buffer appendString:script];
    [_buffer appendString:@"\n"];
    
    if (![_context isStringCompilableUnit:_buffer]) {
        return @{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeIncompletedScript) };
    }
    
    NSError *error;
    XJSValue *val = [_context evaluateString:_buffer error:&error];
    if (val) {
        return @{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeExecuted),
                  kXJSInspectorMessageStringKey :val.toString
                  };
    }
    
    return @{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeExecuted),
              kXJSInspectorMessageErrorKey : error
              };
}

@end
