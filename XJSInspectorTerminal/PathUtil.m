//
//  PathUtil.m
//  XJSInspector
//
//  Created by Xiliang Chen on 14-4-20.
//  Copyright (c) 2014年 Xiliang Chen. All rights reserved.
//

#import "PathUtil.h"

@implementation PathUtil

+ (NSString *)scriptDirectoryPath
{
#ifdef DEBUG
    NSString *file = @(__FILE__);
    return [[file stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Scripts"];
#else
    return [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Scripts"];
#endif
}

+ (NSURL *)URLForFileAtScriptDirectory:(NSString *)file
{
    return [NSURL fileURLWithPath:[[self scriptDirectoryPath] stringByAppendingPathComponent:file]];
}

@end
