//
//  LFRequestQueue.h
//  LFProxy3
//
//  Created by Andre Green on 7/20/14.
//  Copyright (c) 2014 Andre Green. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LFRequestQueue : NSObject

@property(nonatomic, readonly)NSUInteger count;


-(void)enqueue:(id)key;
-(id)dequeue;

-(NSArray*)allObjects;
-(BOOL)isEmpty;

@end
