//
//  XJSServerDelegateTests.m
//  XJSInspector
//
//  Created by Xiliang Chen on 13-11-16.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "XJSBinding.h"
#import "OCMock.h"

#import "XJSServerDelegate_Private.h"
#import "XJSInspectorMessageProtocol.h"

@interface XJSServerDelegateTests : XCTestCase

@end

@implementation XJSServerDelegateTests
{
    XJSServerDelegate *_delegate;
    id _mockServer;
}

- (void)setUp
{
    [super setUp];
    
    _delegate = [[XJSServerDelegate alloc] init];
    
    _mockServer = [OCMockObject mockForClass:[ThoMoServerStub class]];
}

- (void)tearDown
{
    _mockServer = nil;
    _delegate = nil;
    
    [super tearDown];
}

- (void)testInit
{
    XCTAssertNotNil(_delegate.context);
    XCTAssertEqualObjects([_delegate.context class], [XJSContext class]);
}

- (void)testHandleMessage
{
    [[_mockServer expect] send:@{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeExecuted),
                                  kXJSInspectorMessageStringKey : @"84",
                                  kXJSInspectorMessageIDKey : @42 }
                      toClient:@"client"];
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:@{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeJavascript),
                                                                  kXJSInspectorMessageStringKey : @"a = 42\n b = a * 2",
                                                                  kXJSInspectorMessageIDKey : @42 }];
    
    [_delegate server:_mockServer didReceiveData:data fromClient:@"client"];
    
    [_mockServer verify];
    
    {
        XJSValue *val = _delegate.context[@"a"];
        XCTAssertTrue(val.isNumber);
        XCTAssertEqual(val.toInt32, 42);
    }
    
    {
        XJSValue *val = _delegate.context[@"b"];
        XCTAssertTrue(val.isNumber);
        XCTAssertEqual(val.toInt32, 84);
    }
    
    [[_mockServer expect] send:@{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeExecuted),
                                  kXJSInspectorMessageStringKey : @"b" }
                      toClient:@"client"];
    
    data = [NSKeyedArchiver archivedDataWithRootObject:@{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeJavascript),
                                                          kXJSInspectorMessageStringKey : @"a = b; b = 'b'" }];
    
    [_delegate server:_mockServer didReceiveData:data fromClient:@"client"];
    
    [_mockServer verify];
    
    {
        XJSValue *val = _delegate.context[@"a"];
        XCTAssertTrue(val.isNumber);
        XCTAssertEqual(val.toInt32, 84);
    }
    
    {
        XJSValue *val = _delegate.context[@"b"];
        XCTAssertTrue(val.isString);
        XCTAssertEqualObjects(val.toString, @"b");
    }
}

- (void)testHandleIncompletedMessage
{
    [[_mockServer expect] send:@{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeIncompletedScript) }
                      toClient:@"client"];
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:@{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeJavascript),
                                                                  kXJSInspectorMessageStringKey : @"{" }];
    
    [_delegate server:_mockServer didReceiveData:data fromClient:@"client"];
    
    [_mockServer verify];
    
    [[_mockServer expect] send:@{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeIncompletedScript) }
                      toClient:@"client"];
    
    data = [NSKeyedArchiver archivedDataWithRootObject:@{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeJavascript),
                                                          kXJSInspectorMessageStringKey : @"a=42" }];
    
    [_delegate server:_mockServer didReceiveData:data fromClient:@"client"];
    
    [_mockServer verify];
    
    [[_mockServer expect] send:@{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeExecuted),
                                  kXJSInspectorMessageStringKey : @"23" }
                      toClient:@"client"];
    
    data = [NSKeyedArchiver archivedDataWithRootObject:@{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeJavascript),
                                                          kXJSInspectorMessageStringKey : @"b=23}" }];
    
    [_delegate server:_mockServer didReceiveData:data fromClient:@"client"];
    
    [_mockServer verify];
    
    {
        XJSValue *val = _delegate.context[@"a"];
        XCTAssertTrue(val.isNumber);
        XCTAssertEqual(val.toInt32, 42);
    }
    
    {
        XJSValue *val = _delegate.context[@"b"];
        XCTAssertTrue(val.isNumber);
        XCTAssertEqual(val.toInt32, 23);
    }
}

- (void)testErrorScript
{
    [[_mockServer expect] send:[OCMArg checkWithBlock:^BOOL(NSDictionary *dict) {
        return [dict[kXJSInspectorMessageTypeKey] isEqual:@(XJSInspectorMessageTypeExecuted)] &&
            [dict[kXJSInspectorMessageErrorKey] isKindOfClass:[NSError class]];
    }]
                      toClient:@"client"];
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:@{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeJavascript),
                                                                  kXJSInspectorMessageStringKey : @"!;" }];
    
    [_delegate server:_mockServer didReceiveData:data fromClient:@"client"];
    
    [_mockServer verify];
}

- (void)testScriptReturnUndefined
{
    [[_mockServer expect] send:@{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeExecuted),
                                  kXJSInspectorMessageIDKey : @42 }
                      toClient:@"client"];
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:@{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeJavascript),
                                                                  kXJSInspectorMessageStringKey : @"undefined",
                                                                  kXJSInspectorMessageIDKey : @42 }];
    
    [_delegate server:_mockServer didReceiveData:data fromClient:@"client"];
    
    [_mockServer verify];
}

- (void)testCommandReturnUndefined
{
    [[_mockServer expect] send:@{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeExecuted),
                                  kXJSInspectorMessageIDKey : @42 }
                      toClient:@"client"];
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:@{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeCommand),
                                                                  kXJSInspectorMessageStringKey : @"undefined",
                                                                  kXJSInspectorMessageIDKey : @42 }];
    
    [_delegate server:_mockServer didReceiveData:data fromClient:@"client"];
    
    [_mockServer verify];
}

- (void)testCommandReturnArray
{
    [[_mockServer expect] send:@{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeExecuted),
                                  kXJSInspectorMessageDataKey : [NSKeyedArchiver archivedDataWithRootObject:[@[@1, @"test", @YES] mutableCopy]],
                                  kXJSInspectorMessageIDKey : @42 }
                      toClient:@"client"];
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:@{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeCommand),
                                                                  kXJSInspectorMessageStringKey : @"a=42;[1, 'test', true]",
                                                                  kXJSInspectorMessageIDKey : @42 }];
    
    [_delegate server:_mockServer didReceiveData:data fromClient:@"client"];
    
    [_mockServer verify];
    
    {
        XJSValue *val = _delegate.context[@"a"];
        XCTAssertTrue(val.isNumber);
        XCTAssertEqual(val.toInt32, 42);
    }
}

- (void)testCommandReturnData
{
    [_delegate.context createObjCRuntimeWithNamespace:@"objc"];
    
    [[_mockServer expect] send:@{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeExecuted),
                                  kXJSInspectorMessageDataKey : [NSKeyedArchiver archivedDataWithRootObject:[@[@1, @"test", @YES] mutableCopy]],
                                  kXJSInspectorMessageIDKey : @42 }
                      toClient:@"client"];
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:@{ kXJSInspectorMessageTypeKey : @(XJSInspectorMessageTypeCommand),
                                                                  kXJSInspectorMessageStringKey : @"objc.NSKeyedArchiver.archivedDataWithRootObject([1, 'test', true])",
                                                                  kXJSInspectorMessageIDKey : @42 }];
    
    [_delegate server:_mockServer didReceiveData:data fromClient:@"client"];
    
    [_mockServer verify];
}

@end
