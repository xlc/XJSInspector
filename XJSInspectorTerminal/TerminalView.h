//
//  TerminalView.h
//  XJSInspector
//
//  Created by Xiliang Chen on 13-12-5.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TerminalView : NSTextView

@property (nonatomic, copy) void (^inputHandler)(NSString *);

- (void)appendOutput:(NSString *)output;
- (void)appendError:(NSString *)errorMessage;

@end
