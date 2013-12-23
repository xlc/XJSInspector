//
//  XJSInspector.m
//  XJSInspector
//
//  Created by Xiliang Chen on 13-11-6.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "XJSInspector.h"

#import <ThoMoNetworking/ThoMoNetworking.h>
#import <XLCUtils/XLCUtils.h>
#import <XJSBinding/XJSBinding.h>

#import "XJSInspectorMessageProtocol.h"
#import "XJSServerDelegate_Private.h"

@interface XJSInspector ()

+ (void)setContext:(XJSContext *)cx;

@end

@implementation XJSInspector

static NSString *_protocolIdentifier;
static ThoMoServerStub *_server;
static XJSContext *_context;
static XJSServerDelegate *_delegate;

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
                                    kXJSInspectorMessageStringKey : [NSString stringWithFormat:@"%s:%d\t- %@", function, lineno, message],
                                    kXJSInspectorMessageTimestampKey : [NSDate date] };
            [_server sendToAllClients:dict];
        }];
    });
    
    NSString *protocolIden = _protocolIdentifier ?: @"xjsinspector";
    
    @synchronized(self) {
        if (_server) return;
        
        ThoMoServerStub *server = [[ThoMoServerStub alloc] initWithProtocolIdentifier:protocolIden];
        _context = [[XJSContext alloc] init];
        [_context createObjCRuntimeWithNamespace:nil];
        [_context createModuleManager];
        _context.name = @"XJSInspectorContext";
        
        _delegate = [[XJSServerDelegate alloc] initWithContext:_context];
        server.delegate = _delegate;
        [server start];
        
        _server = server;
    }
}

+ (void)stopServer
{
    ThoMoServerStub *server = _server;
    _server = nil;
    _context = nil;
    _delegate = nil;
    [server stop];
}

+ (void)setContext:(XJSContext *)cx
{
    _delegate.context = cx;
}

@end
