//
//  MainWindowController.m
//  XJSInspector
//
//  Created by Xiliang Chen on 13-11-17.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "MainWindowController.h"

#import <XLCUtils/XLCUtils.h>

#import "TerminalView.h"
#import "ServerProxy.h"

@interface MainWindowController () <ServerProxyDelegate>

@property (nonatomic, strong) IBOutlet NSToolbar *toolbar;
@property (nonatomic, strong) IBOutlet TerminalView *terminalView;

@property (nonatomic, strong) NSArray *toolbarItems;

@end

@implementation MainWindowController

- (id)init
{
    return [self initWithWindowNibName:@"MainWindowController"];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    __weak __typeof__(self) weakSelf = self;
    [self.terminalView setInputHandler:^(NSString *input) {
        __typeof__(self) strongSelf = weakSelf;
        [strongSelf.server sendScript:input];
    }];
}

#pragma mark -

- (void)setServer:(ServerProxy *)server
{
    _server.delegate = nil;
    _server = server;
    _server.delegate = self;
}

#pragma mark - ServerProxyDelegate

- (void)server:(ServerProxy *)proxy didExecutedScriptWithOutput:(NSString *)output error:(NSError *)error
{
    if (output) {
        [self.terminalView appendOutput:output];
    }
    if (error) {
        [self.terminalView appendError:[error description]];
    }
}

- (void)serverConnected:(ServerProxy *)proxy
{
    XILOG("connected %@", proxy);
}

- (void)serverDisconnected:(ServerProxy *)proxy
{
    XILOG(@"disconnected %@", proxy);
}

- (void)serverReceivedLogMessage:(NSString *)string withLevel:(NSUInteger)level
{
    [self.terminalView appendLog:string level:level];
}

-(void)serverRequireMoreScript:(ServerProxy *)proxy
{
    // TODO
}

@end
