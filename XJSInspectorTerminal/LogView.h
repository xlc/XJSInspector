//
//  LogView.h
//  XJSInspector
//
//  Created by Xiliang Chen on 14-4-20.
//  Copyright (c) 2014年 Xiliang Chen. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LogView : NSView

@property (nonatomic) NSArray *messageAttributes;

- (void)appendMessage:(NSString *)message withLevel:(NSUInteger)level timestamp:(NSDate *)date;

@end
