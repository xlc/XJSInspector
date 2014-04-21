//
//  TerminalView.h
//  XJSInspector
//
//  Created by Xiliang Chen on 13-12-5.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TerminalView : NSView

@property (nonatomic, copy) void (^inputHandler)(NSString *);

@property (nonatomic, strong) NSDictionary *inputTextAttritube;
@property (nonatomic, strong) NSDictionary *messageTextAttritube;
@property (nonatomic, strong) NSDictionary *errorTextAttritube;
@property (nonatomic, readonly) NSUInteger textLength;

- (void)appendOutput:(NSString *)output;
- (void)appendError:(NSString *)errorMessage;

- (void)markIncomplete:(NSUInteger)loc;

@end
