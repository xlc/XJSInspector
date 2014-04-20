//
//  LogView.m
//  XJSInspector
//
//  Created by Xiliang Chen on 14-4-20.
//  Copyright (c) 2014年 Xiliang Chen. All rights reserved.
//

#import "LogView.h"

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
    }
    return self;
}

- (void)appendMessage:(NSString *)message withLevel:(NSUInteger)level timestamp:(NSDate *)date
{
    [_textView.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:[message stringByAppendingString:@"\n"] attributes:nil]];
}

@end
