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

@interface MainWindowController () <ServerProxyDelegate, NSComboBoxDataSource, NSComboBoxDelegate>

@property (nonatomic, strong) IBOutlet NSToolbar *toolbar;
@property (nonatomic, strong) IBOutlet TerminalView *terminalView;
@property (nonatomic, strong) IBOutlet NSTextView *logView;
@property (nonatomic, strong) IBOutlet NSOutlineView *outlineView;
@property (nonatomic, strong) IBOutlet NSComboBox *contextComboBox;

@property (nonatomic, strong) NSArray *toolbarItems;

@property (nonatomic, strong) NSArray *contextList;

- (void)updateContextList;

@end

@implementation MainWindowController

- (id)init
{
    return [self initWithWindowNibName:@"MainWindowController"];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    [self.terminalView setAutomaticQuoteSubstitutionEnabled:NO];
    
    self.contextComboBox.usesDataSource = YES;
    self.contextComboBox.dataSource = self;
    self.contextComboBox.delegate = self;
    
    __weak __typeof__(self) weakSelf = self;
    [self.terminalView setInputHandler:^(NSString *input) {
        __typeof__(self) strongSelf = weakSelf;
        [strongSelf.server sendScript:input withCompletionHandler:^(BOOL completed, NSString *result, NSError *error) {
            if (!completed) {
                // TODO
            }
            if (result) {
                [strongSelf.terminalView appendOutput:result];
            }
            if (error) {
                [strongSelf.terminalView appendError:[error description]];
            }
        }];
    }];
    
    [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(updateContextList) userInfo:nil repeats:YES];
    [self updateContextList];
    [self.server setContext:0];
}

#pragma mark -

- (void)setServer:(ServerProxy *)server
{
    _server.delegate = nil;
    _server = server;
    _server.delegate = self;
    
    [self updateContextList];
    [_server setContext:0];
}

- (void)setContextList:(NSArray *)contextList
{
    _contextList = contextList;
    [self.contextComboBox reloadData];
}

#pragma mark -

- (void)updateContextList
{
    [self.server getContextList:^(NSArray *contexts) {
        self.contextList = contexts;
        [self.contextComboBox reloadData];
        if (self.contextComboBox.indexOfSelectedItem == -1) {
            [self.contextComboBox selectItemAtIndex:0];
        }
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
    [self.logView.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:[string stringByAppendingString:@"\n"] attributes:nil]];
}

#pragma mark - NSComboBoxDataSource

- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
    return self.contextList.count;
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index
{
    return self.contextList[index];
}

#pragma mark - NSComboBoxDelegate

- (void)comboBoxSelectionDidChange:(NSNotification *)notification
{
    [self.server setContext:self.contextComboBox.indexOfSelectedItem];
}

@end
