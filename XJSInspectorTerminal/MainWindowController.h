//
//  MainWindowController.h
//  XJSInspector
//
//  Created by Xiliang Chen on 13-11-17.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ServerProxy;

@interface MainWindowController : NSWindowController

@property (nonatomic, strong) ServerProxy *server;

- (id)init;

@end
