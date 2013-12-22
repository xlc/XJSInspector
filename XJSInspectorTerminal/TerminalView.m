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
    [self.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:string attributes:attr]];
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
