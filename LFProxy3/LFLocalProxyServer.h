//
//  LFLocalProxyServer.h
//  LFProxy3
//
//  Created by Andre Green on 7/16/14.
//  Copyright (c) 2014 Andre Green. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LFConnection.h"

@interface LFLocalProxyServer : NSObject<LFConnectionDelegate>

@property(nonatomic, assign)int localFD;
@property(nonatomic, assign)int foreignFD;

@property(nonatomic, assign)NSInteger dataIndex;

@property(nonatomic, copy)NSString *localIPAddress;
@property(nonatomic, copy)NSString* foreignIPAddress;

@property(nonatomic, assign)int localPort;
@property(nonatomic, assign)int foreignPort;

@property(nonatomic, strong)NSData *localAddressData;
@property(nonatomic, strong)NSData *foreignAddressData;

@property(nonatomic, copy)NSMutableData *foreignInData;
@property(nonatomic, copy)NSMutableData *foreignOutData;

@property(nonatomic, assign)BOOL isServerListening;
@property(nonatomic, assign)BOOL isForeignCommunication;
@property(nonatomic, assign)BOOL isConnectedToHost;

@property(nonatomic, strong)LFConnection *foreignConnection;

-(id)initWithAddress:(NSString*)address andPort:(int)port;
-(void)start;
-(CFSocketSignature)createSocketSignitureForSocket:(int)socketfd;
@end
