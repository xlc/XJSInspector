//
//  XJSInspector.m
//  XJSInspector
//
//  Created by Xiliang Chen on 13-11-6.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "XJSInspector.h"

#import "ThoMoNetworking.h"
#import "XLCLogging.h"

#import "XJSInspectorMessageProtocol.h"

@implementation XJSInspector

static NSString *_protocolIdentifier;
ThoMoServerStub *_server;

+ (void)setProtocolIdentifier:(NSString *)iden
{
    _protocolIdentifier = iden;
}

+ (NSString *)protocolIdentifier
{
    return _protocolIdentifier;
}

+ (void)startServer
{
    if (_server) return; // already started
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [XLCLogger addLogger:^(XLCLoggingLevel level, const char *function, int lineno, NSString *message) {
            if (!_server) return;
            
            NSDictionary *dict = @{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeRedirectedLog),
                                    kXJSInspectorMessageLoggingLevelKey : @(level),
                                    kXJSInspectorMessageStringKey : [NSString stringWithFormat:@"%s:%d\t= %@", function, lineno, message]};
            [_server sendToAllClients:dict];
        }];
    });
    
    NSString *protocolIden = _protocolIdentifier ?: @"xjsinspector";
    
    @synchronized(self) {
        if (_server) return;
        
        ThoMoServerStub *server = [[ThoMoServerStub alloc] initWithProtocolIdentifier:protocolIden];
        [server start];
        
        _server = server;
    }
}

+ (void)stopServer
{
    ThoMoServerStub *server = _server;
    _server = nil;
    [server stop];
}

@end
