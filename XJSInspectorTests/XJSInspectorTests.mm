//
//  XJSInspectorTests.m
//  XJSInspectorTests
//
//  Created by Xiliang Chen on 13-11-6.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "XJSContext.h"
#import "XJSValue.h"

@interface XJSInspectorTests : XCTestCase

@end

@implementation XJSInspectorTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample
{
    XJSContext *context = [[XJSContext alloc] init];
    
    context[@"a"] = @1;
    
    NSLog(@"%@", [context[@"a"] debugDescription]);
}

@end
