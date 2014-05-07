//
//  XJSInspectorTerminalAppDelegate.h
//  XJSInspectorTerminal
//
//  Created by Xiliang Chen on 13-11-16.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MainWindowController;
@class XJSContext;

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, copy, readonly) NSArray *mainWindowControllers;
@property (nonatomic, strong) XJSContext *context;

- (IBAction)createWindow;

@end
