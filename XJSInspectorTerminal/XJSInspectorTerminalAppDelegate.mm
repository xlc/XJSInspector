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

#import "MainWindowController.h"
#import "ServerProxy.h"
#import "PathUtil.h"

@interface AppDelegate () <ThoMoClientDelegateProtocol>

@property (nonatomic, readonly) NSMutableArray *mutableMainWindowControllers;
@property (nonatomic, strong) ThoMoClientStub *client;
@property (nonatomic, strong) XJSContext *context;
@property (weak) IBOutlet NSMenuItem *createWindowMenuItem;

@end

@implementation AppDelegate

@synthesize mutableMainWindowControllers = _mutableMainWindowControllers;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [XJSInspector setProtocolIdentifier:@"xjs"];
    [XJSInspector startServer];
    
    self.createWindowMenuItem.action = @selector(createWindow);
    
    [self createWindow];
    
    ThoMoClientStub *client = [[ThoMoClientStub alloc] initWithProtocolIdentifier:@"xjs"];
    client.delegate = self;
    self.client = client;
    
    [self.client start];
    
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
    
    NSString *serverString = [self.client.connectedServers lastObject];
    if (serverString) {
        controller.server = [[ServerProxy alloc] initWithThoMoServerProxy:[self.client serverProxyForId:serverString]];
    }
    
    __block __weak id observer = [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowWillCloseNotification object:controller.window queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [self.mutableMainWindowControllers removeObject:controller];
        
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
    }];
    
    [controller showWindow:self];
}

#pragma mark - ThoMoClientDelegateProtocol

- (void)client:(ThoMoClientStub *)theClient didConnectToServer:(NSString *)aServerIdString
{
    // TODO what to do?
    for (MainWindowController *controller in self.mainWindowControllers) {
        if (!controller.server) {
            controller.server = [[ServerProxy alloc] initWithThoMoServerProxy:[theClient serverProxyForId:aServerIdString]];
        }
    }
}

@end
