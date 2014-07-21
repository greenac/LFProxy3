//
//  LFURLProtocol.m
//  LFProxy3
//
//  Created by Andre Green on 7/16/14.
//  Copyright (c) 2014 Andre Green. All rights reserved.
//

#import "LFURLProtocol.h"
#import "LFConnection.h"
#import "LFLocalProxyServer.h"
#import "LFAppDelegate.h"
#import "LFRequestQueue.h"
#import "LFProtocolStore.h"

@interface LFURLProtocol()

@property(nonatomic, strong)LFProtocolStore *store;
@property(nonatomic, strong)LFLocalProxyServer *server;

@end


@implementation LFURLProtocol

static NSString *CONNECTION_KEY = @"connection_key";
static NSString *REQUEST_KEY = @"request_key";
static NSString *CLIENT_KEY = @"client_key";

-(LFProtocolStore*)store{
    
    if (!_store) {
        
        _store = [LFProtocolStore sharedStore];
    }
    
    return _store;
}

-(LFLocalProxyServer*)server{
    
    if (!_server) {
        
        LFAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        _server = appDelegate.server;
    }
    
    return _server;
}

+(BOOL)canInitWithRequest:(NSURLRequest *)request{
    
    BOOL shouldHandle = YES;
    
    if ([request.URL.absoluteString rangeOfString:@"https"].location != NSNotFound) {
        
        NSLog(@"request is https");
    }
    else if([request.URL.absoluteString rangeOfString:@"http"].location != NSNotFound){
        
        NSLog(@"request is http");
    }
    else{
        
        shouldHandle = NO;
    }
    
    return shouldHandle;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    
    return request;
}

- (void)startLoading {
    
    static NSUInteger counter = 0;
    NSLog(@"number of requests handled: %lu", (unsigned long)++counter);
    
    LFConnection *connection = [[LFConnection alloc] initWithServerAddressData:self.server.localAddressData request:self.request protocol:[self requestProtocol]];
    
    [self addCurrentInstanceToQueueWithConnection:connection];
    
    // if there are no active requests, send this request to proxy
    if (self.store.activeRequests.allObjects.count == 0) {
        
        [self sendWaitingRequestToProxy];
    }
}

- (void)stopLoading {
    NSLog(@"stopped loading");
    

}

-(void)sendWaitingRequestToProxy{
    
    NSDictionary * requestDict = [self getNextRequestFromQueue];
    
    [self.store.activeRequests addObject:requestDict];
    
    NSURLRequest *request = [requestDict objectForKey:REQUEST_KEY];
    
    [self.store.activeRequests addObject:requestDict];
    
    LFConnection *connection = [requestDict objectForKey:CONNECTION_KEY];
    connection.delegate = self;
    [connection connect];
}

-(void)addCurrentInstanceToQueueWithConnection:(LFConnection*)connection{
    
    NSDictionary *connDict = @{CONNECTION_KEY: connection, REQUEST_KEY: self.request, CLIENT_KEY: self.client};
    
    [self.store.queue enqueue:connDict];
}

-(NSDictionary*)getNextRequestFromQueue{
    
    return [self.store.queue dequeue];
}

-(NSString*)requestProtocol{
    
    NSString *url = self.request.URL.absoluteString.lowercaseString;
    
    if ([url rangeOfString:@"https"].location != NSNotFound) {
        
        return @"https";
    }
    else if ([url rangeOfString:@"http"].location != NSNotFound){
        
        return @"http";
    }
    else{
        
        return nil;
    }
}

#pragma mark - LFConnection delegate methods

-(void)connectionHasReceivedData:(LFConnection *)connection{
    
    NSString *dataString = [[NSString alloc] initWithData:connection.outData encoding:NSUTF8StringEncoding];
    NSLog(@"data passed back to LFURLprotocol: %@", dataString);
}
@end
