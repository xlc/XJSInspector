//
//  MainWindowController.m
//  XJSInspector
//
//  Created by Xiliang Chen on 13-11-17.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "MainWindowController.h"

#import <XLCUtils/XLCUtils.h>
#import <XJSBinding/NSError_XJSErrorConstants.h>
#import <ThoMoNetworking/ThoMoNetworking.h>

#import "TerminalView.h"
#import "LogView.h"
#import "ServerProxy.h"
#import "PathUtil.h"

@interface MainWindowController () <ServerProxyDelegate, ThoMoClientDelegateProtocol, NSTextFieldDelegate>

@property (strong) IBOutlet NSTextField *applicationTextField;
@property (strong) IBOutlet NSPopUpButton *contextButton;

@property (nonatomic, strong) TerminalView *terminalView;
@property (nonatomic, strong) LogView *logView;

@property (nonatomic, strong) ThoMoClientStub *client;

- (IBAction)connect:(id)sender;
- (IBAction)selectContext:(id)sender;

- (void)updateContexts;

@end

@implementation MainWindowController {
    BOOL _connected;
    NSString *_currentContext;
}

- (id)init
{
    return [self initWithWindowNibName:@"MainWindowController"];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    NSDictionary *dict;
    
    self.window.contentView = [[XLCXMLObject objectWithContentsOfURL:[PathUtil URLForFileAtScriptDirectory:@"MainWindowController.xml"] error:NULL] createWithOutputDictionary:&dict];
    
    self.terminalView = dict[@"terminalView"];
    self.logView = dict[@"logView"];
    
    __weak __typeof__(self) weakSelf = self;
    [self.terminalView setInputHandler:^(NSString *input) {
        __typeof__(self) strongSelf = weakSelf;
        
        NSUInteger loc = strongSelf.terminalView.textLength;
        
        if (strongSelf->_connected) {
            
            [strongSelf.server sendScript:input withCompletionHandler:^(BOOL completed, NSString *result, NSError *error) {
                [strongSelf.terminalView markComplete:completed atLocation:loc];
                if (result) {
                    [strongSelf.terminalView appendOutput:result];
                }
                if (error) {
                    NSString *errorMessage;
                    if ([[error domain] isEqualTo:XJSErrorDomain]) {
                        errorMessage = [error userInfo][XJSErrorMessageKey];
                    }
                    if ([errorMessage length] == 0) {
                        errorMessage = [error description];
                    }
                    [strongSelf.terminalView appendError:errorMessage];
                }
            }];
            
        } else {
            dispatch_after(DISPATCH_TIME_NOW, dispatch_get_main_queue(), ^{
                [strongSelf.terminalView markComplete:true atLocation:loc];
                [strongSelf.terminalView appendError:@"No server connected"];
            });
            
        }
    }];
    
    self.applicationTextField.stringValue = @"xjs";
    self.applicationTextField.delegate = self;
    [self connect:nil];
}

- (IBAction)connect:(id)sender
{
    [self.client stop];
    self.server = nil;
    
    ThoMoClientStub *client = [[ThoMoClientStub alloc] initWithProtocolIdentifier:self.applicationTextField.stringValue];
    client.delegate = self;
    self.client = client;
    
    [self.client start];
}

- (IBAction)selectContext:(id)sender {
    [self.server setContext:self.contextButton.indexOfSelectedItem];
    _currentContext = self.contextButton.titleOfSelectedItem;
    // TODO indicate context changed
}

- (void)updateContexts
{
    [self.server getContextList:^(NSArray *contexts) {
        [self.contextButton removeAllItems];
        [self.contextButton addItemsWithTitles:contexts];
        if (!_currentContext && contexts.count) {
            _currentContext = contexts[0];
            [self.server setContext:0];
        }
        [self.contextButton selectItemWithTitle:_currentContext];
    }];
}

#pragma mark -

- (void)setServer:(ServerProxy *)server
{
    _server.delegate = nil;
    _server = server;
    _server.delegate = self;
    
    [self updateContexts];
}

#pragma mark - ServerProxyDelegate

- (void)serverConnected:(ServerProxy *)proxy
{
    XILOG("connected %@", proxy);
    _connected = YES;
}

- (void)serverDisconnected:(ServerProxy *)proxy
{
    XILOG(@"disconnected %@", proxy);
    _connected = NO;
}

- (void)server:(ServerProxy *)proxy receivedLogMessage:(NSString *)string withLevel:(NSUInteger)level timestamp:(NSDate *)date
{
    [self.logView appendMessage:string withLevel:level timestamp:date];
}

#pragma mark - ThoMoClientDelegateProtocol

- (void)client:(ThoMoClientStub *)theClient didConnectToServer:(NSString *)aServerIdString
{
    if (!self.server) {
        self.server = [[ServerProxy alloc] initWithThoMoServerProxy:[self.client serverProxyForId:aServerIdString]];
    }
}


@end
