//
//  XJSInspectorTerminalTests.m
//  XJSInspectorTerminalTests
//
//  Created by Xiliang Chen on 13-11-27.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "XJSInspectorTerminalAppDelegate.h"
#import "MainWindowController.h"

@interface XJSInspectorTerminalTests : XCTestCase

@end

@implementation XJSInspectorTerminalTests
{
    AppDelegate *_app;
}

- (void)setUp
{
    [super setUp];
    
    _app = [[AppDelegate alloc] init];
}

- (void)tearDown
{
    _app = nil;
    
    [super tearDown];
}

- (void)testNewWindow
{
    __weak id weakobj;
    
    @autoreleasepool {
        XCTAssertEqual(_app.mainWindowControllers.count, (NSUInteger)0);
        
        [_app newWindow];
        
        XCTAssertEqual(_app.mainWindowControllers.count, (NSUInteger)1);
        
        MainWindowController *controller = [_app.mainWindowControllers lastObject];
        weakobj = controller;
        
        XCTAssertTrue([controller isKindOfClass:[MainWindowController class]]);
        
        [controller close];
        
        XCTAssertEqual(_app.mainWindowControllers.count, (NSUInteger)0);
    }
    
    XCTAssert(weakobj == nil, "MainWindowController not released");
}

@end
