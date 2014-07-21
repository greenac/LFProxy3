//
//  LFProtocolStore.m
//  LFProxy3
//
//  Created by Andre Green on 7/21/14.
//  Copyright (c) 2014 Andre Green. All rights reserved.
//

#import "LFProtocolStore.h"
#import "LFConnection.h"
#import "LFRequestQueue.h"

@implementation LFProtocolStore

-(id)init{
    
    self = [super init];
    
    if (self) {
        
        _queue          = [[LFRequestQueue alloc] init];
        _activeRequests = [[NSMutableSet alloc] init];
    }
    
    return self;
}

+(id)allocWithZone:(struct _NSZone *)zone{
    
    return [self sharedStore];
}

+(LFProtocolStore*)sharedStore{
    
    static LFProtocolStore *sharedStore = nil;
    
    if (!sharedStore) {
        
        sharedStore = [[super allocWithZone:nil] init];
    }
    
    return sharedStore;
}
@end
