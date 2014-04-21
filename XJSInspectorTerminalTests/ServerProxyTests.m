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
    [[_mockServer expect] sendObject:OCMOCK_ANY];
    
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
                                        kXJSInspectorMessageStringKey : @"a=1",
                                        kXJSInspectorMessageIDKey : @2
                                        }];

    NSError *error = [NSError errorWithDomain:@"test" code:1 userInfo:nil];
    __block BOOL received = NO;
    
    [_proxy sendScript:@"a=1" withCompletionHandler:^(BOOL completed, NSString *result, NSError *receivedError) {
        XCTAssertTrue(completed);
        XCTAssertEqualObjects(result, @"output");
        XCTAssertEqualObjects(receivedError, error);
        received = YES;
    }];
    
    NSDictionary *dict = @{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeExecuted),
                            kXJSInspectorMessageStringKey : @"output",
                            kXJSInspectorMessageErrorKey : error,
                            kXJSInspectorMessageIDKey : @2,
                            };
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dict];
    [_proxy serverProxy:_mockServer didReceiveData:data];
    
    [_mockServer verify];
    
    XCTAssertTrue(received, "completion handler should be executed");
}

- (void)testSendEmptyScript
{
    [_proxy sendScript:@"\n" withCompletionHandler:^(BOOL completed, NSString *result, NSError *error) {
        XCTFail("empty script should not be executed");
    }];
    
    [_mockServer verify];
}

- (void)testSendIncompletedScript
{
    {
        [[_mockServer expect] sendObject:@{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeJavascript),
                                            kXJSInspectorMessageStringKey : @"{",
                                            kXJSInspectorMessageIDKey : @2
                                            }];
        
        __block BOOL received = NO;
        
        [_proxy sendScript:@"{" withCompletionHandler:^(BOOL completed, NSString *result, NSError *receivedError) {
            XCTAssertFalse(completed);
            received = YES;
        }];
        
        NSDictionary *dict = @{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeIncompletedScript),
                                kXJSInspectorMessageIDKey : @2
                                };
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dict];
        [_proxy serverProxy:_mockServer didReceiveData:data];
        
        [_mockServer verify];
        
        XCTAssertTrue(received, "completion handler should be executed");
    }
    
    {
        [[_mockServer expect] sendObject:@{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeJavascript),
                                            kXJSInspectorMessageStringKey : @"a=1",
                                            kXJSInspectorMessageIDKey : @3
                                            }];
        
        __block BOOL received = NO;
        
        [_proxy sendScript:@"a=1" withCompletionHandler:^(BOOL completed, NSString *result, NSError *receivedError) {
            XCTAssertFalse(completed);
            received = YES;
        }];
        
        NSDictionary *dict = @{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeIncompletedScript),
                                kXJSInspectorMessageIDKey : @3
                                };
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dict];
        [_proxy serverProxy:_mockServer didReceiveData:data];
        
        [_mockServer verify];
        
        XCTAssertTrue(received, "completion handler should be executed");
    }
    
    {
        [[_mockServer expect] sendObject:@{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeJavascript),
                                            kXJSInspectorMessageStringKey : @"b=2}",
                                            kXJSInspectorMessageIDKey : @4
                                            }];
        
        __block BOOL received = NO;
        
        [_proxy sendScript:@"b=2}" withCompletionHandler:^(BOOL completed, NSString *result, NSError *receivedError) {
            XCTAssertTrue(completed);
            received = YES;
        }];
        
        NSDictionary *dict = @{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeExecuted),
                                kXJSInspectorMessageStringKey : @"2",
                                kXJSInspectorMessageIDKey : @4
                                };
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dict];
        [_proxy serverProxy:_mockServer didReceiveData:data];
        
        [_mockServer verify];
        
        XCTAssertTrue(received, "completion handler should be executed");
    }
}

- (void)testMultipleMessage
{
    [[_mockServer expect] sendObject:@{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeJavascript),
                                        kXJSInspectorMessageStringKey : @"a=1",
                                        kXJSInspectorMessageIDKey : @2
                                        }];
    
    __block BOOL received = NO;
    
    [_proxy sendScript:@"a=1" withCompletionHandler:^(BOOL completed, NSString *result, NSError *receivedError) {
        received = YES;
    }];
   
    
    [[_mockServer expect] sendObject:@{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeJavascript),
                                        kXJSInspectorMessageStringKey : @"a=2",
                                        kXJSInspectorMessageIDKey : @3
                                        }];
    
    __block BOOL received2 = NO;
    
    [_proxy sendScript:@"a=2" withCompletionHandler:^(BOOL completed, NSString *result, NSError *receivedError) {
        received2 = YES;
    }];
    
    {
        NSDictionary *dict = @{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeExecuted),
                                kXJSInspectorMessageIDKey : @3,
                                };
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dict];
        [_proxy serverProxy:_mockServer didReceiveData:data];
    }

    XCTAssertFalse(received);
    XCTAssertTrue(received2);
    
    {
        NSDictionary *dict = @{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeExecuted),
                                kXJSInspectorMessageIDKey : @2,
                                };
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dict];
        [_proxy serverProxy:_mockServer didReceiveData:data];
    }
    
    XCTAssertTrue(received);
    XCTAssertTrue(received2);
    
    [_mockServer verify];
    
}

- (void)testDelegateRedirectedLog
{
    NSDate *date = [NSDate date];
    [[_delegate expect] server:_proxy receivedLogMessage:@"log" withLevel:0 timestamp:date];
    
    NSDictionary *dict = @{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeRedirectedLog),
                            kXJSInspectorMessageStringKey : @"log",
                            kXJSInspectorMessageLoggingLevelKey : @0,
                            kXJSInspectorMessageTimestampKey : date,
                            kXJSInspectorMessageIDKey : @2
                            };
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dict];
    [_proxy serverProxy:_mockServer didReceiveData:data];
    
    [_delegate verify];
}

- (void)testDelegateDisconnected
{
    [[_delegate expect] serverDisconnected:_proxy];
    
    [_proxy serverProxyDidDisconnect:_mockServer];
    
    [_delegate verify];
}

- (void)testDelegateConnected
{
    [[_delegate expect] serverConnected:_proxy];
    
    [_proxy serverProxyDidResumeConnection:_mockServer];
    
    [_delegate verify];
}

@end
