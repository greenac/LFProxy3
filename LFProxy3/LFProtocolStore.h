//
//  LFProtocolStore.h
//  LFProxy3
//
//  Created by Andre Green on 7/21/14.
//  Copyright (c) 2014 Andre Green. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LFConnection.h"
#import "LFLocalProxyServer.h"
#import "LFRequestQueue.h"

@interface LFProtocolStore : NSObject

@property(nonatomic, strong)id <NSURLProtocolClient>currentClient;
@property(nonatomic, strong)NSURLRequest *currentRequest;
@property(nonatomic, strong)LFConnection *currentConnection;

@property(nonatomic, strong)LFRequestQueue *queue;

@property(nonatomic, copy)NSMutableSet *activeRequests;

@property(nonatomic, strong)NSDictionary *currentRequestInfo;

+(LFProtocolStore*)sharedStore;

@end
