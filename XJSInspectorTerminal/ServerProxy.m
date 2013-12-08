//
//  ServerProxy.m
//  XJSInspector
//
//  Created by Xiliang Chen on 13-12-7.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "ServerProxy.h"

#import <ThoMoNetworking/ThoMoNetworking.h>
#import <XLCUtils/XLCUtils.h>

#import "XJSInspectorMessageProtocol.h"

@interface ServerProxy () <ThoMoServerProxyDelegate>

@end

@implementation ServerProxy

- (id)initWithThoMoServerProxy:(ThoMoServerProxy *)proxy
{
    self = [super init];
    if (self) {
        _proxy = proxy;
        _proxy.delegate = self;
    }
    return self;
}

#pragma mark -

-(NSString *)description
{
    return [NSString stringWithFormat:@"%@-%@", [super description], self.proxy.connectionString];
}

#pragma mark -

- (void)sendScript:(NSString *)script
{
    [self.proxy sendObject:@{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeJavascript),
                          kXJSInspectorMessageStringKey : script
                          }];
}

#pragma mark - ThoMoServerProxyDelegate

- (void)serverProxy:(ThoMoServerProxy *)serverProxy didReceiveData:(NSData *)data
{
    NSDictionary *dict = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    if (![dict isKindOfClass:[NSDictionary class]]) {
        XFAIL(@"Unexpected object received: %@, from data: %@", dict, data);
        return;
    }
    
    switch ([dict[kXJSInspectorMessageTypeKey] unsignedIntegerValue]) {
        case XJSInspectorMessageTypeExecuted:
            [self.delegate server:self didExecutedScriptWithOutput:dict[kXJSInspectorMessageStringKey] error:dict[kXJSInspectorMessageErrorKey]];
            break;
            
        case XJSInspectorMessageTypeIncompletedScript:
            [self.delegate serverRequireMoreScript:self];
            break;
            
        case XJSInspectorMessageTypeRedirectedLog:
            [self.delegate server:self receivedLogMessage:dict[kXJSInspectorMessageStringKey] withLevel:[dict[kXJSInspectorMessageLoggingLevelKey] unsignedIntegerValue]];
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
