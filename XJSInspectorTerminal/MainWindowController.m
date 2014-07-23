//
//  MainWindowController.m
//  XJSInspector
//
//  Created by Xiliang Chen on 13-11-17.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "MainWindowController.h"

#import <XLCUtils/XLCUtils.h>
#import <XJSBinding/XJSBinding.h>
#import <ThoMoNetworking/ThoMoNetworking.h>

#import "TerminalView.h"
#import "LogView.h"
#import "ServerProxy.h"
#import "PathUtil.h"
#import "XJSInspectorTerminalAppDelegate.h"

@interface MainWindowController () <ServerProxyDelegate, ThoMoClientDelegateProtocol, NSTextFieldDelegate>

@property (strong) IBOutlet NSTextField *applicationTextField;
@property (strong) IBOutlet NSPopUpButton *contextButton;

@property (nonatomic, strong) TerminalView *terminalView;
@property (nonatomic, strong) LogView *logView;

@property (nonatomic, strong) ThoMoClientStub *client;

- (IBAction)connect:(id)sender;
- (IBAction)selectContext:(id)sender;
- (IBAction)runScript:(id)sender;
- (IBAction)rerunScript:(id)sender;

- (void)updateContexts;
- (void)sendScriptWithContent:(NSString *)content;

- (void)executeCommand:(NSString *)command completionHandler:(void(^)(NSString *result, NSString *error))handler;
- (NSString *)sendScript:(NSString *)path;
- (NSString *)stringByExpandingTildeInPath:(NSString *)string;
- (NSString *)uploadFrom:(NSString *)fromPath to:(NSString *)toPath;
- (NSString *)uploadFileFrom:(NSString *)fromPath to:(NSString *)toPath;

@end

@implementation MainWindowController {
    BOOL _connected;
    NSString *_currentContext;
    NSURL *_lastScript;
    NSTimer *_updateContextTimer;
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

        if ([input hasPrefix:@"#"]) {
            [strongSelf executeCommand:input completionHandler:^(NSString *result, NSString *error) {
                [strongSelf.terminalView markComplete:true atLocation:loc];
                if (error) {
                    [strongSelf.terminalView appendError:error];
                }
                if (result) {
                    [strongSelf.terminalView appendOutput:result];
                }
            }];
            
        } else {
            
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
        }
        
    }];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSArray *history = [userDefaults objectForKey:@"TerminalViewHistory"];
    if (history) {
        self.terminalView.history = [history mutableCopy];
    }
    
    self.applicationTextField.delegate = self;
    [self connect:nil];
    
    _updateContextTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(updateContexts) userInfo:nil repeats:YES];
    
    NSString *cwd = [userDefaults objectForKey:@"CurrentWorkingDirectory"];
    if (cwd) {
        [[NSFileManager defaultManager] changeCurrentDirectoryPath:cwd];
    }
}

- (void)windowWillClose:(NSNotification *)notification {
    [_updateContextTimer invalidate];
    _updateContextTimer = nil;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSMutableArray *history = self.terminalView.history;
    if (history.count > 100) {
        [history removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, history.count - 100)]];
    }
    [userDefaults setObject:self.terminalView.history forKey:@"TerminalViewHistory"];
    
    [userDefaults setObject:[[NSFileManager defaultManager] currentDirectoryPath] forKey:@"CurrentWorkingDirectory"];
    
    [userDefaults synchronize];
    
    self.client = nil;
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

- (IBAction)connect:(id)sender
{
    NSString *iden = self.applicationTextField.stringValue;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([iden length]) {
        [userDefaults setObject:iden forKey:@"LastProtocolIdentifier"];
        [userDefaults synchronize];
    } else {
        iden = [userDefaults stringForKey:@"LastProtocolIdentifier"];
        self.applicationTextField.stringValue = iden;
    }
    
    self.server = nil;
    
    ThoMoClientStub *client = [[ThoMoClientStub alloc] initWithProtocolIdentifier:self.applicationTextField.stringValue];
    self.client = client;
}

- (IBAction)selectContext:(id)sender
{
    [self.server setContext:self.contextButton.indexOfSelectedItem];
    _currentContext = self.contextButton.titleOfSelectedItem;
    // TODO indicate context changed
}

- (IBAction)runScript:(id)sender
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    
    panel.canChooseDirectories = NO;
    panel.canChooseFiles = YES;
    panel.allowsMultipleSelection = NO;
    panel.allowedFileTypes = @[@"js"];
    panel.allowsOtherFileTypes = YES;
    
    NSString *lastDir = [userDefaults stringForKey:@"LastUsedScriptDirectory"];
    if (lastDir) {
        panel.directoryURL = [NSURL URLWithString:lastDir];
    }
    
    [panel runModal];

    [userDefaults setObject:[panel.directoryURL absoluteString] forKey:@"LastUsedScriptDirectory"];
    [userDefaults synchronize];
    
    NSURL *selectedFile = [panel URL];
    if (selectedFile) {
        NSString *content = [[NSString alloc] initWithContentsOfURL:selectedFile usedEncoding:NULL error:NULL];
        if (content) {
            _lastScript = selectedFile;
            [self sendScriptWithContent:content];
        }
    }
}

- (IBAction)rerunScript:(id)sender {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if (_lastScript) {
        [userDefaults setObject:[_lastScript absoluteString] forKey:@"LaseRanScriptFilePath"];
    } else {
        _lastScript = [NSURL URLWithString:[userDefaults stringForKey:@"LaseRanScriptFilePath"]];
    }
    [userDefaults synchronize];
    if (_lastScript) {
        NSString *content = [[NSString alloc] initWithContentsOfURL:_lastScript usedEncoding:NULL error:NULL];
        [self sendScriptWithContent:content];
    }
}

- (void)sendScriptWithContent:(NSString *)content
{
    [self.terminalView appendOutput:[NSString stringWithFormat:@"Script: %@", [_lastScript relativePath]]];
    [self.server sendScript:content withCompletionHandler:^(BOOL completed, NSString *result, NSError *error) {
        if (result) {
            [self.terminalView appendOutput:result];
        }
        if (error) {
            NSString *errorMessage;
            if ([[error domain] isEqualTo:XJSErrorDomain]) {
                errorMessage = [error userInfo][XJSErrorMessageKey];
            }
            if ([errorMessage length] == 0) {
                errorMessage = [error description];
            }
            [self.terminalView appendError:errorMessage];
        }
    }];
}

- (NSString *)stringByExpandingTildeInPath:(NSString *)string
{
    return [string stringByExpandingTildeInPath];
}

#pragma mark -

- (void)setServer:(ServerProxy *)server
{
    _server.delegate = nil;
    _server = server;
    _server.delegate = self;
    
    [self updateContexts];
}

- (void)setClient:(ThoMoClientStub *)client
{
    [_client stop];
    _client.delegate = nil;
    
    _client = client;
    
    _client.delegate = self;
    [_client start];
}

#pragma mark - handle command

- (void)executeCommand:(NSString *)command completionHandler:(void(^)(NSString *result, NSString *error))handler
{
    AppDelegate *delegate = [[NSApplication sharedApplication] delegate];
    XJSValue *module = [delegate.context.moduleManager requireModule:@"command"];
    XASSERT_NOTNULL(module);
    NSArray *arr = [command componentsSeparatedByString:@" "];
    XJSValue *func = module[[arr[0] substringFromIndex:1]];
    if (func) {
        NSMutableArray *args = [arr mutableCopy];
        args[0] = self;
        
        __block NSError *error;
        void (^oldHandler)(XJSContext *, NSError *) = func.context.errorHandler;
        [func.context setErrorHandler:^(XJSContext *cx, NSError *err) {
            if (oldHandler) {
                oldHandler(cx, error);
            }
            error = err;
        }];
        XJSValue *result = [func callWithArguments:args];
        if (handler) {
            dispatch_after(DISPATCH_TIME_NOW, dispatch_get_main_queue(), ^{
                NSString *errorMessage = nil;
                if (error) {
                    if ([[error domain] isEqualTo:XJSErrorDomain]) {
                        errorMessage = [error userInfo][XJSErrorMessageKey];
                    }
                    if ([errorMessage length] == 0) {
                        errorMessage = [error description];
                    }
                }
                handler(result.isNullOrUndefined ? nil : result.toString, errorMessage);
            });
        }
    } else {
        if (handler) {
            dispatch_after(DISPATCH_TIME_NOW, dispatch_get_main_queue(), ^{
                handler(nil, @"Invalid command");
            });
        }
    }
}

- (NSString *)sendScript:(NSString *)path
{
    NSError *error;
    NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    if (content) {
        [self.server sendScript:content withCompletionHandler:^(BOOL completed, NSString *result, NSError *error) {
            if (result) {
                [self.terminalView appendOutput:result];
            }
            if (error) {
                NSString *errorMessage;
                if ([[error domain] isEqualTo:XJSErrorDomain]) {
                    errorMessage = [error userInfo][XJSErrorMessageKey];
                }
                if ([errorMessage length] == 0) {
                    errorMessage = [error description];
                }
                [self.terminalView appendError:errorMessage];
            }
        }];
    }
    
    return [error description];
}

- (NSString *)uploadFrom:(NSString *)fromPath to:(NSString *)toPath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    BOOL isDir;
    if ([fileManager fileExistsAtPath:fromPath isDirectory:&isDir]) {
        if (isDir) {
            NSDirectoryEnumerator * dirEnum = [fileManager enumeratorAtPath:fromPath];
            NSString *file;
            NSMutableArray *messages = [NSMutableArray array];
            while ((file = [dirEnum nextObject])) {
                if ([file hasPrefix:@"."]) {
                    continue;
                }
                NSString *fullPath = [fromPath stringByAppendingPathComponent:file];
                NSString *fullToPath = [toPath stringByAppendingPathComponent:file];
                NSString *msg = [self uploadFileFrom:fullPath to:fullToPath];
                if (msg) {
                    [messages addObject:msg];
                }
            }
            return [messages componentsJoinedByString:@"\n"];
        } else {
            return [self uploadFileFrom:fromPath to:toPath];
        }
    } else {
        return [NSString stringWithFormat:@"File not found: %@", fromPath];
    }
}

- (NSString *)uploadFileFrom:(NSString *)fromPath to:(NSString *)toPath
{
    NSString *data = [[NSData dataWithContentsOfFile:fromPath] base64Encoding];
    
    NSString *command = [NSString stringWithFormat:
                         @"(function(){\n"
                         "var objc = require('xjs/objc');\n"
                         "var log = require('xjs/log');\n"
                         "var data = '%@';\n"
                         "var path = '%@';\n"
                         "var filename = '%@';\n"
                         "var NSURLIsDirectoryKey = %@;\n"
                         "var NSDocumentDirectory = %lu;\n"
                         "var NSUserDomainMask = %lu;\n"
                         "var fileManager = objc.NSFileManager.defaultManager();\n"
                         "var documentDirURL = fileManager.URLForDirectory_inDomain_appropriateForURL_create_error(NSDocumentDirectory, NSUserDomainMask, null, true, null);\n"
                         "var url = documentDirURL.URLByAppendingPathComponent(path);\n"
                         "var isDir = url.resourceValuesForKeys_error([NSURLIsDirectoryKey], null)[NSURLIsDirectoryKey];\n"
                         "if (isDir) url = url.URLByAppendingPathComponent(filename);\n"
                         "log(url);\n"
                         "var filedata = objc.NSData.alloc().initWithBase64EncodedString_options(data, 0);\n"
                         "log(filedata.length());\n"
                         "var success = filedata.writeToURL_atomically(url, true);\n"
                         "log(success);"
                         "})();"
                         ,
                         data,
                         toPath,
                         [fromPath lastPathComponent],
                         NSURLIsDirectoryKey,
                         (unsigned long)NSDocumentDirectory,
                         (unsigned long)NSUserDomainMask
                         ];
    
    [self.server sendCommand:command withCompletionHandler:^(BOOL completed, NSData *result, NSError *error) {
        if (error) {
            [self.terminalView appendError:[NSString stringWithFormat:@"Error durint execute command 'upload %@ %@'. Error: %@", fromPath, toPath, error]];
        }
    }];
    
    return nil;
}


#pragma mark - ServerProxyDelegate

- (void)serverConnected:(ServerProxy *)proxy
{
    XILOG("connected %@", proxy);
    _connected = YES;
    
    [self updateContexts];
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
