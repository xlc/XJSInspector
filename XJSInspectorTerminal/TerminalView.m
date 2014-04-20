//
//  TerminalView.m
//  XJSInspector
//
//  Created by Xiliang Chen on 13-12-5.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "TerminalView.h"

#import <Carbon/Carbon.h>

@interface TerminalView () <NSTextViewDelegate>

- (void)appendString:(NSString *)string attritubes:(NSDictionary *)attr;

@end

@implementation TerminalView
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
        
        _scrollView.documentView = _textView;
        
        [self addSubview:_scrollView];
        
        self.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    }
    return self;
}

// TODO different font for input/output/error/log

- (void)appendOutput:(NSString *)output
{
    [self appendString:output attritubes:nil];
}

- (void)appendError:(NSString *)errorMessage
{
    [self appendString:errorMessage attritubes:nil];
}

- (void)appendString:(NSString *)string attritubes:(NSDictionary *)attr
{
    if ([string length] == 0) {
        return;
    }
    if (![string hasSuffix:@"\n"]) {
        string = [string stringByAppendingString:@"\n"];
    }
    [_textView.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:string attributes:attr]];
    _startIndex = _textView.textStorage.length;
}

#pragma mark -

- (void)keyDown:(NSEvent *)theEvent
{
    [super keyDown:theEvent];
    
    if ([theEvent keyCode] == kVK_Return) {
        if (self.inputHandler) {
            self.inputHandler([_textView.string substringFromIndex:_startIndex]);
        }
        _startIndex = _textView.textStorage.length;
    }
}

#pragma mark - NSTextViewDelegate

- (BOOL)textView:(NSTextView *)textView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString
{
    return YES;
}

@end
