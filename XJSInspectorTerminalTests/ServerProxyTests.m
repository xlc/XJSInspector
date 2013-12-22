//
//  ServerProxyTests.m
//  XJSInspector
//
//  Created by Xiliang Chen on 13-12-8.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <XCTest/XCTest.h>

#include <OCMock/OCMock.h>
#include <ThoMoNetworking/ThoMoNetworking.h>

#include "XJSInspectorMessageProtocol.h"
#include "ServerProxy.h"

@interface ServerProxyTests : XCTestCase

@end

@implementation ServerProxyTests
{
    ServerProxy<ThoMoServerProxyDelegate> *_proxy;
    id _mockServer;
    id _delegate;
}

- (void)setUp
{
    [super setUp];
    
    _mockServer = [OCMockObject mockForClass:[ThoMoServerProxy class]];
    [[_mockServer expect] setDelegate:OCMOCK_ANY];
    
    _proxy = (id)[[ServerProxy alloc] initWithThoMoServerProxy:_mockServer];
    
    [_mockServer verify];
    
    _delegate = [OCMockObject mockForProtocol:@protocol(ServerProxyDelegate)];
    
    _proxy.delegate = _delegate;
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testSendScript
{
    [[_mockServer expect] sendObject:@{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeJavascript),
                                  kXJSInspectorMessageStringKey : @"a=1"
                                  }];
    
    [_proxy sendScript:@"a=1"];
    
    [_mockServer verify];
}

- (void)testSendEmptyScript
{
    [_proxy sendScript:@"\n"];
    
    [_mockServer verify];
}

- (void)testDelegateDidExecuteScript
{
    NSError *error = [NSError errorWithDomain:@"test" code:1 userInfo:nil];
    [[_delegate expect] server:_proxy didExecutedScriptWithOutput:@"output" error:error];
    
    NSDictionary *dict = @{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeExecuted),
                            kXJSInspectorMessageStringKey : @"output",
                            kXJSInspectorMessageErrorKey : error};
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dict];
    [_proxy serverProxy:_mockServer didReceiveData:data];
}

- (void)testDelegateRequireMoreScript
{
    [[_delegate expect] serverRequireMoreScript:_proxy];
    
    NSDictionary *dict = @{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeIncompletedScript) };
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dict];
    [_proxy serverProxy:_mockServer didReceiveData:data];
}

- (void)testDelegateRedirectedLog
{
    NSDate *date = [NSDate date];
    [[_delegate expect] server:_proxy receivedLogMessage:@"log" withLevel:0 timestamp:date];
    
    NSDictionary *dict = @{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeRedirectedLog),
                            kXJSInspectorMessageStringKey : @"log",
                            kXJSInspectorMessageLoggingLevelKey : @0,
                            kXJSInspectorMessageTimestamp : date };
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dict];
    [_proxy serverProxy:_mockServer didReceiveData:data];
}

- (void)testDelegateDisconnected
{
    [[_delegate expect] serverDisconnected:_proxy];
    
    [_proxy serverProxyDidDisconnect:_mockServer];
}

- (void)testDelegateConnected
{
    [[_delegate expect] serverConnected:_proxy];
    
    [_proxy serverProxyDidResumeConnection:_mockServer];
}

@end
