//
//  XJSInspectorProtocol.h
//  XJSInspector
//
//  Created by Xiliang Chen on 13-11-15.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, XJSInspectorMessageType)
{
    XJSInspectorMessageTypeClientCodeBegin = 0,
    
    // js code to execute, keys: string
    XJSInspectorMessageTypeJavascript,
    
    XJSInspectorMessageTypeServerCodeBegin = 100,
    
    // script executed, keys: string, error
    XJSInspectorMessageTypeExecuted,
    // incompleted script, need more input, keys: none
    XJSInspectorMessageTypeIncompletedScript,
    // log from XLCLOG, keys: string, logging level
    XJSInspectorMessageTypeRedirectedLog,
};


#define kXJSInspectorMessageTypeKey @"kXJSInspectorMessageTypeKey"
#define kXJSInspectorMessageStringKey @"kXJSInspectorMessageStringKey"
#define kXJSInspectorMessageErrorKey @"kXJSInspectorMessageErrorKey"
#define kXJSInspectorMessageLoggingLevelKey @"kXJSInspectorMessageLoggingLevelKey"