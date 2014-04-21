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
#import "LogView.h"
#import "ServerProxy.h"
#import "PathUtil.h"

@interface MainWindowController () <ServerProxyDelegate>

@property (nonatomic, strong) TerminalView *terminalView;
@property (nonatomic, strong) LogView *logView;

@end

@implementation MainWindowController

- (id)init
{
    return [self initWithWindowNibName:@"MainWindowController"];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    NSDictionary *dict;
    
    self.window.contentView = [[XLCXMLObject objectWithContentsOfURL:[PathUtil URLForFileAtScriptDirectory:@"MainWindowController.xml"] error:NULL] createWithOutputDictionary:&dict];;
    
    self.terminalView = dict[@"terminalView"];
    self.logView = dict[@"logView"];
    
    __weak __typeof__(self) weakSelf = self;
    [self.terminalView setInputHandler:^(NSString *input) {
        __typeof__(self) strongSelf = weakSelf;
        NSUInteger loc = strongSelf.terminalView.textLength;
        [strongSelf.server sendScript:input withCompletionHandler:^(BOOL completed, NSString *result, NSError *error) {
            if (!completed) {
                [strongSelf.terminalView markIncomplete:loc];
            }
            if (result) {
                [strongSelf.terminalView appendOutput:result];
            }
            if (error) {
                [strongSelf.terminalView appendError:[error description]];
            }
        }];
    }];
    
    [self.window makeFirstResponder:self.terminalView];
}

#pragma mark -

- (void)setServer:(ServerProxy *)server
{
    _server.delegate = nil;
    _server = server;
    _server.delegate = self;
    
    [_server getContextList:^(NSArray *contexts) {
        [self.server setContext:0];
    }];
}

#pragma mark - ServerProxyDelegate

- (void)serverConnected:(ServerProxy *)proxy
{
    XILOG("connected %@", proxy);
}

- (void)serverDisconnected:(ServerProxy *)proxy
{
    XILOG(@"disconnected %@", proxy);
}

- (void)server:(ServerProxy *)proxy receivedLogMessage:(NSString *)string withLevel:(NSUInteger)level timestamp:(NSDate *)date
{
    [self.logView appendMessage:string withLevel:level timestamp:date];
}

@end
