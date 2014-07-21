//
//  LFNode.m
//  LFProxy3
//
//  Created by Andre Green on 7/20/14.
//  Copyright (c) 2014 Andre Green. All rights reserved.
//

#import "LFNode.h"

@implementation LFNode

-(id)initWithKey:(id)key{
    
    self = [super init];
    
    if (self) {
        
        _next   = nil;
        _prev   = nil;
        _key    = key;
    }
    
    return self;
}



@end
