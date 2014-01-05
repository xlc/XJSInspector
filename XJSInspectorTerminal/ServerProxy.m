//
//  ServerProxy.m
//  XJSInspector
//
//  Created by Xiliang Chen on 13-12-7.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "ServerProxy.h"

#import <libkern/OSAtomic.h>
#import <ThoMoNetworking/ThoMoNetworking.h>
#import <XLCUtils/XLCUtils.h>

#import "XJSInspectorMessageProtocol.h"

@interface ServerProxy () <ThoMoServerProxyDelegate>

- (void)sendScript:(NSString *)script isCommand:(BOOL)isCommand withCompletionHandler:(void (^)(BOOL completed, id result, NSError *error))handler;

- (id)nextID;

@end

@implementation ServerProxy
{
    volatile int32_t _count;
    NSMutableDictionary *_handlerDict;
}

- (id)initWithThoMoServerProxy:(ThoMoServerProxy *)proxy
{
    self = [super init];
    if (self) {
        _proxy = proxy;
        _proxy.delegate = self;
        _handlerDict = [NSMutableDictionary dictionary];
        
        [self sendCommand:@"require.provide('global', function(){})" withCompletionHandler:nil];
    }
    return self;
}

#pragma mark -

-(NSString *)description
{
    return [NSString stringWithFormat:@"%@-%@", [super description], self.proxy.connectionString];
}

#pragma mark -

- (id)nextID
{
    return @(OSAtomicIncrement32(&_count));
}

- (void)sendScript:(NSString *)script withCompletionHandler:(void (^)(BOOL completed, NSString *result, NSError *error))handler
{
    [self sendScript:script isCommand:NO withCompletionHandler:handler];
}

- (void)sendCommand:(NSString *)script withCompletionHandler:(void (^)(BOOL completed, NSData *result, NSError *error))handler
{
    [self sendScript:script isCommand:YES withCompletionHandler:handler];
}

- (void)sendScript:(NSString *)script isCommand:(BOOL)isCommand withCompletionHandler:(void (^)(BOOL completed, id result, NSError *error))handler
{
    script = [script stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([script length] == 0) { // no need to send empty string
        return;
    }
    
    id nextID = [self nextID];
    
    if (handler) {
        _handlerDict[nextID] = [handler copy];
    }
    
    [self.proxy sendObject:@{ kXJSInspectorMessageTypeKey : @(isCommand ? XJSInspectorMessageTypeCommand : XJSInspectorMessageTypeJavascript),
                              kXJSInspectorMessageStringKey : script,
                              kXJSInspectorMessageIDKey : nextID
                              }];
}

#pragma mark -

- (void)getContextList:(void (^)(NSArray *contexts))handler
{
    XASSERT_NOTNULL(handler);
    NSString *script =
    @"(function(){"
    "var cxs = require('xjs/objc').XJSContext.allContexts();"
    "var arr = [];"
    "for (var i = 0; i < cxs.length; i++) {"
        "var cx = cxs[i];"
        "var name = cx.name();"
        "if (name) {"
            "arr.push([name, cx]);"
        "}"
    "};"
    "arr.sort();"
    "var contextList = [];"
    "var names = [];"
    "for (var i = 0; i < arr.length; i++) {"
        "names.push(arr[i][0]);"
        "contextList.push(arr[i][1]);"
    "};"
    "require('global').contextList = contextList;"
    "return names;"
    "})()"
    ;
    
    [self sendCommand:script withCompletionHandler:^(BOOL completed, NSData *result, NSError *error) {
        if (error) {
            XILOG(@"failed to request context list with error: %@", error);
            handler(nil);
            return;
        }
        if (result) {
            NSArray *arr = [NSKeyedUnarchiver unarchiveObjectWithData:result];
            if (![arr isKindOfClass:[NSArray class]]) {
                XWLOG(@"unexpected object received: %@", arr);
                handler(nil);
                return;
            }
            handler(arr);
        }
    }];
}

- (void)setContext:(NSUInteger)contextIndex
{
    NSString *script = [NSString stringWithFormat:
                        @"require('xjs/objc').XJSInspector.setContext(require('global').contextList[%d]);"
                        , (unsigned)contextIndex];
    
    [self sendCommand:script withCompletionHandler:nil];
    
}

#pragma mark - ThoMoServerProxyDelegate

- (void)serverProxy:(ThoMoServerProxy *)serverProxy didReceiveData:(NSData *)data
{
    NSDictionary *dict = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    if (![dict isKindOfClass:[NSDictionary class]]) {
        XFAIL(@"Unexpected object received: %@, from data: %@", dict, data);
        return;
    }

    void (^handler)(BOOL completed, id result, NSError *error) = _handlerDict[dict[kXJSInspectorMessageIDKey]];
    
    switch ([dict[kXJSInspectorMessageTypeKey] unsignedIntegerValue]) {
        case XJSInspectorMessageTypeExecuted:
            if (handler) {
                id result = dict[kXJSInspectorMessageStringKey] ?: dict[kXJSInspectorMessageDataKey];
                handler(YES, result, dict[kXJSInspectorMessageErrorKey]);
            }
            break;
            
        case XJSInspectorMessageTypeIncompletedScript:
            if (handler) {
                handler(NO, nil, nil);
            }
            break;
            
        case XJSInspectorMessageTypeRedirectedLog:
            [self.delegate server:self receivedLogMessage:dict[kXJSInspectorMessageStringKey]
                        withLevel:[dict[kXJSInspectorMessageLoggingLevelKey] unsignedIntegerValue]
                        timestamp:dict[kXJSInspectorMessageTimestampKey]];
            break;
            
        default:
            XFAIL(@"Unexpected object received: %@", dict);
            break;
    }
}

- (void)serverProxyDidDisconnect:(ThoMoServerProxy *)serverProxy
{
    [self.delegate serverDisconnected:self];
}

- (void)serverProxyDidResumeConnection:(ThoMoServerProxy *)serverProxy
{
    [self.delegate serverConnected:self];
}

@end
