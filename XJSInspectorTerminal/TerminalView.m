//
//  TerminalView.m
//  XJSInspector
//
//  Created by Xiliang Chen on 13-12-5.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "TerminalView.h"

#import <Carbon/Carbon.h>

@interface TerminalViewTextView : NSTextView

@property (nonatomic) NSUInteger caretIndex;
@property (nonatomic) NSUInteger startIndex;

- (void)updateCaret;

@end

@interface TerminalView () <NSTextViewDelegate>

- (void)appendString:(NSString *)string attritubes:(NSDictionary *)attr;

@end

@implementation TerminalView
{
    TerminalViewTextView *_textView;
    NSScrollView *_scrollView;
    BOOL _wasCompleted;
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
        
        _textView = [[TerminalViewTextView alloc] initWithFrame:frameRect];
        _textView.minSize = NSMakeSize(0, frameRect.size.height);
        _textView.maxSize = NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX);
        _textView.verticallyResizable = YES;
        _textView.horizontallyResizable = NO;
        _textView.autoresizingMask = NSViewWidthSizable;
        _textView.textContainer.containerSize = NSMakeSize(frameRect.size.width, CGFLOAT_MAX);
        _textView.textContainer.widthTracksTextView = YES;
        _textView.delegate = self;
        
        _scrollView.documentView = _textView;
        
        [self addSubview:_scrollView];
        
        self.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        
        _wasCompleted = YES;
    }
    return self;
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow {
    if (newWindow && _textView.textStorage.length == 0) {
        [_textView.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:@"> " attributes:self.inputTextAttritube]];
        _textView.startIndex = _textView.caretIndex = _textView.textStorage.length;
    }
}

#pragma mark -

- (NSUInteger)textLength
{
    return _textView.textStorage.length;
}

- (void)appendOutput:(NSString *)output
{
    [self appendString:output attritubes:self.messageTextAttritube];
}

- (void)appendError:(NSString *)errorMessage
{
    [self appendString:errorMessage attritubes:self.errorTextAttritube];
}

- (void)appendString:(NSString *)string attritubes:(NSDictionary *)attr
{
    if ([string length] == 0) {
        return;
    }
    if (![string hasSuffix:@"\n"]) {
        string = [string stringByAppendingString:@"\n"];
    }
    NSUInteger loc = [_textView.textStorage.string rangeOfString:@"\n" options:NSBackwardsSearch].location;
    if (loc == NSNotFound) {
        loc = 0;
    } else {
        loc++;
    }
    _textView.caretIndex += string.length;
    _textView.startIndex += string.length;
    [_textView.textStorage insertAttributedString:[[NSAttributedString alloc] initWithString:string attributes:attr] atIndex:loc];
    
    [_textView scrollRangeToVisible:NSMakeRange(_textView.caretIndex, 0)];
}

- (void)markComplete:(BOOL)complete atLocation:(NSUInteger)loc
{
    [_textView.textStorage replaceCharactersInRange:NSMakeRange(loc+1, 1) withString:complete ? @">" : @" "];
    _wasCompleted = complete;
}

#pragma mark - NSTextViewDelegate

- (BOOL)textView:(NSTextView *)textView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString
{
    if ([replacementString length]) { // insert
        
        BOOL hasEnter = NO;
        if ([replacementString isEqualTo:@"\n"]) {
            replacementString = @"";
            hasEnter = YES;
        } else if ([replacementString rangeOfString:@"\n"].location != NSNotFound) { // multi-line string
            hasEnter = YES;
        }
        
        _textView.caretIndex++;
        [_textView.textStorage insertAttributedString:[[NSAttributedString alloc] initWithString:replacementString attributes:self.inputTextAttritube] atIndex:_textView.caretIndex - 1];
        
        if (hasEnter) {
            if (self.inputHandler) {
                self.inputHandler([_textView.string substringFromIndex:_textView.startIndex]);
            }
            
            [_textView.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:_wasCompleted ? @"\n> " : @"\n  " attributes:self.inputTextAttritube]];
            
            _textView.startIndex = _textView.textStorage.length;
            _textView.caretIndex = _textView.startIndex;
        }
        
    } else { // delete
        if (_textView.caretIndex != _textView.startIndex) {
            _textView.caretIndex--;
            [_textView.textStorage replaceCharactersInRange:NSMakeRange(_textView.caretIndex, 1) withString:@""];
        }
    }
    
    [_textView scrollRangeToVisible:NSMakeRange(_textView.caretIndex, 0)];
    
    return NO;
}

@end

@implementation TerminalViewTextView {
    CGRect _prevCaretRect;
}

- (BOOL)shouldDrawInsertionPoint
{
    return NO;
}

- (void)setSelectedRanges:(NSArray *)ranges affinity:(NSSelectionAffinity)affinity stillSelecting:(BOOL)stillSelectingFlag {
    if (ranges.count == 1) {
        NSRange range = [[ranges lastObject] rangeValue];
        if (range.length == 0) {
            if (range.location < self.startIndex) {
                ranges = @[ [NSValue valueWithRange:NSMakeRange(self.caretIndex, 0)] ];
            } else {
                self.caretIndex = range.location;
            }
        }
    }
    
    [super setSelectedRanges:ranges affinity:affinity stillSelecting:stillSelectingFlag];
    [self updateCaret];
}

- (void)drawRect:(NSRect)dirtyRect
{
    // clear previous caret
    [self.backgroundColor drawSwatchInRect:_prevCaretRect];
    
    // draw text
    [super drawRect:dirtyRect];
    
    // draw caret
    NSUInteger rectCount;
    NSUInteger caretIndex = self.caretIndex;
    NSRectArray arr = [self.layoutManager rectArrayForCharacterRange:NSMakeRange(caretIndex, caretIndex >= self.textStorage.length ? 0 : 1) withinSelectedCharacterRange:NSMakeRange(NSNotFound, 0) inTextContainer:self.textContainer rectCount:&rectCount];
    if (arr && rectCount) {
        _prevCaretRect = arr[0];
        if (_prevCaretRect.size.width == 0) {
            CGFloat h = _prevCaretRect.size.height;
            _prevCaretRect.origin.x += 1;
            _prevCaretRect.size.width = h / 2;
        }
        _prevCaretRect.origin.y += 1;
        _prevCaretRect.size.height -= 2;
        NSColor *color = [NSColor colorWithWhite:0 alpha:0.3];
        [color setFill];
        if ([[self window] firstResponder] == self) {
            NSRectFillUsingOperation(_prevCaretRect, NSCompositeSourceOver);
        } else {
            NSFrameRect(_prevCaretRect);
        }
    }
}

- (BOOL)becomeFirstResponder
{
    [self updateCaret];
    return [super becomeFirstResponder];
}

- (BOOL)resignFirstResponder
{
    [self updateCaret];
    return [super resignFirstResponder];
}

#pragma mark -

- (void)updateCaret
{
    if (self.textStorage.length) {
        CGRect rect = [self.layoutManager lineFragmentRectForGlyphAtIndex:self.textStorage.length-1 effectiveRange:NULL withoutAdditionalLayout:YES];
        [self setNeedsDisplayInRect:rect avoidAdditionalLayout:YES];
    } else {
        [self setNeedsDisplay:YES];
    }
}

@end
