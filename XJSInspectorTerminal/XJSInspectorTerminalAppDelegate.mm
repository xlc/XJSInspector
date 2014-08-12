//
//  XJSInspectorTerminalAppDelegate.m
//  XJSInspectorTerminal
//
//  Created by Xiliang Chen on 13-11-16.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "XJSInspectorTerminalAppDelegate.h"

#import <ThoMoNetworking/ThoMoNetworking.h>
#import <XJSInspector/XJSInspector.h>
#import <XJSBinding/XJSBinding.h>
#import <XLCUtils/XLCUtils.h>
#import "DDTTYLogger.h"
#import "DDASLLogger.h"

#import "MainWindowController.h"
#import "ServerProxy.h"
#import "PathUtil.h"

@interface AppDelegate ()

@property (nonatomic, readonly) NSMutableArray *mutableMainWindowControllers;
@property (weak) IBOutlet NSMenuItem *createWindowMenuItem;

@end

@implementation AppDelegate

@synthesize mutableMainWindowControllers = _mutableMainWindowControllers;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    id<DDLogger> logger = [DDTTYLogger sharedInstance];
    [logger setLogFormatter:[[XLCDefaultLogFormatter alloc] init]];
    [DDLog addLogger:logger];
    logger = [DDASLLogger sharedInstance];
    [logger setLogFormatter:[[XLCDefaultLogFormatter alloc] init]];
    [DDLog addLogger:logger];
    
    [XJSInspector setProtocolIdentifier:@"xjs"];
    [XJSInspector startServer];
    
    self.createWindowMenuItem.action = @selector(createWindow);
    
    [self createWindow];
    
    XJSContext *cx = [[XJSContext alloc] init];
    cx.name = @"main";
    [cx createModuleManager];
    [cx createObjCRuntimeWithNamespace:nil];
    cx.moduleManager.paths = @[ [PathUtil scriptDirectoryPath] ];
    self.context = cx;
}

#pragma mark -

- (NSArray *)mainWindowControllers
{
    return [self.mutableMainWindowControllers copy];
}

- (NSMutableArray *)mutableMainWindowControllers
{
    if (!_mutableMainWindowControllers) {
        _mutableMainWindowControllers = [NSMutableArray array];
    }
    return _mutableMainWindowControllers;
}

#pragma mark -

- (IBAction)createWindow
{
    MainWindowController *controller = [[MainWindowController alloc] init];
    
    [self.mutableMainWindowControllers addObject:controller];
    
    __block __weak id observer = [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowWillCloseNotification object:controller.window queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [self.mutableMainWindowControllers removeObject:controller];
        
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
    }];
    
    [controller showWindow:self];
}

@end
