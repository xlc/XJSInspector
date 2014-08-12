//
//  LogView.m
//  XJSInspector
//
//  Created by Xiliang Chen on 14-4-20.
//  Copyright (c) 2014年 Xiliang Chen. All rights reserved.
//

#import "LogView.h"

#import <XLCUtils/XLCLogging.h>

@implementation LogView
{
    NSUInteger _startIndex;
    NSTextView *_textView;
    NSScrollView *_scrollView;
}

- (instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        _scrollView = [[NSScrollView alloc] initWithFrame:frameRect];
        
        _scrollView.borderType = NSNoBorder;
        _scrollView.hasVerticalScroller = YES;
        _scrollView.hasHorizontalScroller = NO;
        _scrollView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        
        _textView = [[NSTextView alloc] initWithFrame:frameRect];
        _textView.minSize = NSMakeSize(0, frameRect.size.height);
        _textView.maxSize = NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX);
        _textView.verticallyResizable = YES;
        _textView.horizontallyResizable = NO;
        _textView.autoresizingMask = NSViewWidthSizable;
        _textView.textContainer.containerSize = NSMakeSize(frameRect.size.width, CGFLOAT_MAX);
        _textView.textContainer.widthTracksTextView = YES;
        _textView.editable = NO;
        
        _scrollView.documentView = _textView;
        
        [self addSubview:_scrollView];
        
        self.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        
        CGFloat fontSize = [NSFont systemFontSize];
        _messageAttributes = @[
                               // debug
                               @{ NSForegroundColorAttributeName : [NSColor grayColor],
                                  NSFontAttributeName : [NSFont systemFontOfSize:fontSize]},
                               // info
                               @{ NSForegroundColorAttributeName : [NSColor blackColor],
                                  NSFontAttributeName : [NSFont systemFontOfSize:fontSize]},
                               // warn
                               @{ NSForegroundColorAttributeName : [NSColor orangeColor],
                                  NSFontAttributeName : [NSFont systemFontOfSize:fontSize]},
                               // error
                               @{ NSForegroundColorAttributeName : [NSColor redColor],
                                  NSFontAttributeName : [NSFont systemFontOfSize:fontSize]},
                               ];
    }
    return self;
}

- (void)appendMessage:(NSString *)message withLevel:(NSUInteger)level timestamp:(NSDate *)date
{
    switch (level) {
        case LOG_FLAG_DEBUG:
            level = 0;
            break;
            
        case LOG_FLAG_INFO:
            level = 1;
            break;
        
        default:
        case LOG_FLAG_WARN:
            level = 2;
            break;
            
        case LOG_FLAG_ERROR:
            level = 3;
            break;
            
    }
    id attr;
    if (self.messageAttributes.count >= level) {
        attr = self.messageAttributes[level];
    } else {
        attr = [self.messageAttributes lastObject];
    }

    
    if (![message hasSuffix:@"\n"]) {
        message = [message stringByAppendingString:@"\n"];
    }
    
    NSAttributedString *messageString = [[NSAttributedString alloc] initWithString:message attributes:attr];
    
    [_textView.textStorage appendAttributedString:messageString];
    
    [_textView scrollRangeToVisible:NSMakeRange(_textView.textStorage.length, 0)];
}

@end
