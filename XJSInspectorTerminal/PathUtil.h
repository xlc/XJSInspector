//
//  PathUtil.h
//  XJSInspector
//
//  Created by Xiliang Chen on 14-4-20.
//  Copyright (c) 2014年 Xiliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PathUtil : NSObject

+ (NSString *)scriptDirectoryPath;
+ (NSURL *)URLForFileAtScriptDirectory:(NSString *)file;

@end
