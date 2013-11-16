//
//  XJSInspector.h
//  XJSInspector
//
//  Created by Xiliang Chen on 13-11-6.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XJSInspector : NSObject

+ (void)setProtocolIdentifier:(NSString *)iden;
+ (NSString *)protocolIdentifier;

+ (void)startServer;
+ (void)stopServer;

@end
