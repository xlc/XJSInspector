//
//  ServerProxy.h
//  XJSInspector
//
//  Created by Xiliang Chen on 13-12-7.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ThoMoServerProxy;

@protocol ServerProxyDelegate;

@interface ServerProxy : NSObject

@property (nonatomic, strong, readonly) ThoMoServerProxy *proxy;
@property (nonatomic, weak) id<ServerProxyDelegate> delegate;

- (id)initWithThoMoServerProxy:(ThoMoServerProxy *)proxy;

- (void)sendScript:(NSString *)script;

@end

@protocol ServerProxyDelegate <NSObject>

- (void)server:(ServerProxy *)proxy didExecutedScriptWithOutput:(NSString *)output error:(NSError *)error;
- (void)serverRequireMoreScript:(ServerProxy *)proxy;
- (void)server:(ServerProxy *)proxy receivedLogMessage:(NSString *)string withLevel:(NSUInteger)level;

- (void)serverDisconnected:(ServerProxy *)proxy;
- (void)serverConnected:(ServerProxy *)proxy;

@end
