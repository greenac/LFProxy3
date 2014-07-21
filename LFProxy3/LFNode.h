//
//  LFNode.h
//  LFProxy3
//
//  Created by Andre Green on 7/20/14.
//  Copyright (c) 2014 Andre Green. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LFNode : NSObject

@property(nonatomic, strong)LFNode *next;
@property(nonatomic, strong)LFNode *prev;
@property(nonatomic, strong)id key;


-(id)initWithKey:(id)key;

@end
