//
//  LFConnection.h
//  LFProxy3
//
//  Created by Andre Green on 7/16/14.
//  Copyright (c) 2014 Andre Green. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol LFConnectionDelegate;

@interface LFConnection : NSObject <NSStreamDelegate>

@property(nonatomic, strong)NSInputStream *inputStream;
@property(nonatomic, strong)NSOutputStream *outputStream;
@property(nonatomic, strong)NSString *hostName;
@property(nonatomic, assign)int port;
@property(nonatomic, copy)NSMutableData *outData;
@property(nonatomic, copy)NSMutableData *inData;
@property(nonatomic, weak)NSData *serverAddressData;

@property(nonatomic, copy)NSString *message;
@property(nonatomic, strong)NSDictionary *proxyInfo;
@property(nonatomic, copy)NSString *protocolType;
@property(nonatomic, weak)NSURLRequest *request;
@property(nonatomic, assign)NSUInteger bytesRead;
@property(nonatomic, assign)NSUInteger bytesWritten;

@property(nonatomic, weak)id <LFConnectionDelegate>delegate;

-(id)initWithServerAddressData:(NSData*)addData request:(NSURLRequest*)request protocol:(NSString*)protocol;

-(id)initWithHostName:(NSString*)hostName port:(int)port andProtocol:(NSString*)protocol;

-(void)connect;



@end


@protocol LFConnectionDelegate <NSObject>

-(void)connectionHasReceivedData:(LFConnection*)connection;

@end