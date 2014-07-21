//
//  LFRequestQueue.m
//  LFProxy3
//
//  Created by Andre Green on 7/20/14.
//  Copyright (c) 2014 Andre Green. All rights reserved.
//

#import "LFRequestQueue.h"
#import "LFNode.h"

@interface LFRequestQueue()
    
@property(nonatomic, strong)LFNode *head;
@property(nonatomic, strong)LFNode *tail;

@property(nonatomic, readwrite)NSUInteger count;

-(BOOL)isEmpty;

@end

@implementation LFRequestQueue

-(id)init{
    
    self = [super init];
    
    if (self) {
        
        _count  = 0;
        _head   = nil;
        _tail   = nil;
    }
    
    return self;
}

-(void)enqueue:(id)key{
    
    if (!key) {
        return;
    }
    
    LFNode *newNode = [[LFNode alloc] initWithKey:key];
    
    if ([self isEmpty]) {
        
        self.head = newNode;
        self.tail = newNode;
    }
    else{
        
        self.tail.next = newNode;
        newNode.prev = self.tail;
        self.tail = newNode;
    }
    
    self.count++;
}

-(id)dequeue{
    
    if ([self isEmpty]) {
        
        return nil;
    }
    
    id key = self.head.key;
    
    LFNode *newHead = self.head.next;
    self.head.next = nil;
    newHead.prev = nil;
    self.head = newHead;
    
    self.count--;
    
    return key;
}

-(NSArray*)allObjects{
    
    NSMutableArray *objects = [[NSMutableArray alloc] init];
    
    LFNode *node = self.head;
    
    while (node) {
        
        [objects addObject:node.key];
        node = node.next;
    }
    
    return objects;
}

-(BOOL)isEmpty{
    
    return (self.count == 0) ? YES:NO;
}
@end
