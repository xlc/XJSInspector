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

@end

@implementation TerminalView
{
    NSUInteger _startIndex;
}

// TODO different font for input/output/error/log

- (void)appendOutput:(NSString *)output
{
    [self.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:output]];
    _startIndex = self.textStorage.length;
}

- (void)appendError:(NSString *)errorMessage
{
    [self.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:errorMessage]];
    _startIndex = self.textStorage.length;
}

- (void)appendLog:(NSString *)log level:(NSUInteger)level
{
    [self.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:log]];
    _startIndex = self.textStorage.length;
}

#pragma mark -

- (void)keyDown:(NSEvent *)theEvent
{
    [super keyDown:theEvent];
    
    if ([theEvent keyCode] == kVK_Return) {
        if (self.inputHandler) {
            self.inputHandler([self.string substringFromIndex:_startIndex]);
        }
        _startIndex = self.textStorage.length;
    }
}

#pragma mark - NSTextViewDelegate

- (BOOL)textView:(NSTextView *)textView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString
{
    return YES;
}

@end
