//
//  XJSServerDelegate.h
//  XJSInspector
//
//  Created by Xiliang Chen on 13-11-13.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ThoMoNetworking.h"

@class XJSContext;

@interface XJSServerDelegate : NSObject <ThoMoServerDelegateProtocol>

@property (strong) XJSContext *context;
@property (strong, readonly) XJSContext *commandContext;

- (id)initWithContext:(XJSContext *)context;

@end
