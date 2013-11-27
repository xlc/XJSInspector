//
//  MainWindowController.m
//  XJSInspector
//
//  Created by Xiliang Chen on 13-11-17.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "MainWindowController.h"

@interface MainWindowController ()

@property (nonatomic, strong) IBOutlet NSToolbar *toolbar;

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
    

}

@end
