//
//  LFLocalProxyServer.m
//  LFProxy3
//
//  Created by Andre Green on 7/16/14.
//  Copyright (c) 2014 Andre Green. All rights reserved.
//

#import "LFLocalProxyServer.h"
#import "LFConnection.h"

#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/types.h>
#include <sys/un.h>
#include <ifaddrs.h>
#include <net/if.h>

@implementation LFLocalProxyServer



#define MAX_BUFFER_SIZE 1024
#define IOS_CELLULAR    @"pdp_ip0"
#define IOS_WIFI        @"en0"
#define IP_ADDR_IPv4    @"ipv4"
#define IP_ADDR_IPv6    @"ipv6"


-(id)initWithAddress:(NSString *)address andPort:(int)port{
    
    self = [super init];
    
    if (self) {
        
        _dataIndex              = 0;
        _localFD                = -1;
        _foreignFD              = -1;
        
        _localIPAddress         = address;
        _localPort              = port;
        
        _isForeignCommunication = NO;
        
        _foreignInData          = [[NSMutableData alloc] init];
        _foreignOutData         = [[NSMutableData alloc] init];
    }
    
    return self;
}

-(void)start{
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        BOOL foundPort = NO;
        int error;
        
        while (!foundPort) {
            // server will look for open port and assign it to address data
            self.localFD = socket(AF_INET, SOCK_STREAM, 0);
            
            struct sockaddr_in address;
            memset(&address, 0, sizeof(address));
            address.sin_len = sizeof(address);
            address.sin_family = PF_INET;
            address.sin_port = self.localPort;
            address.sin_addr.s_addr = inet_addr([self.localIPAddress UTF8String]);
            
            error = bind(self.localFD, (struct sockaddr*)&address, sizeof(address));
            
            if (error == 0) {
                
                self.localAddressData = [NSData dataWithBytes:&address length:sizeof(address)];
                
                struct sockaddr_in *serverAddress = (struct sockaddr_in*)self.localAddressData.bytes;
                
                char *ipstr = malloc(INET_ADDRSTRLEN);
                struct in_addr *ipv4addr = &serverAddress->sin_addr;
                ipstr = inet_ntoa(*ipv4addr);
                
                NSLog(@"address bound to socket: %d, at address: %s, on port: %d", self.localFD, ipstr, [self getLocalSocketPort]);
                foundPort = YES;
            }
            else{
                
                NSLog(@"ERROR BINDING SOCKET TO ADDRESS");
                self.localPort++;
            }
        }
        
        error = listen(self.localFD, 10);
        
        if (error < 0){
            NSLog(@"ERROR: socket not able to listen on port %d.\nSearching for open socket...", [self getLocalSocketPort]);
        }
        else{
            NSLog(@"socket listening on port: %d", [self getLocalSocketPort]);
        }
        
        struct sockaddr_in fromAddress;
        
        char buffer[MAX_BUFFER_SIZE];
        
        unsigned int fromAddressSize = sizeof(fromAddress);
        
        
        // server should loop through this code forever.
        // server should assign value to listening socket though accept
        // for each new connection
        
        BOOL shouldContinue = YES;

        while (shouldContinue) {
            
            int listeningSocket = accept(self.localFD, (struct sockaddr*)&fromAddress, &fromAddressSize);
            
            if (listeningSocket < 0) {
                
                char b[256];
                int errorNum = strerror_r(errno, b, sizeof(b));
                NSLog(@"errno: %d", errorNum);
                NSLog(@"ERROR -- could not accept communication on listening socket: %d", listeningSocket);
            }
            else{
                
                NSLog(@"Accepting communication on listening socket");
            }
            
            NSLog(@"handling client %s", inet_ntoa(fromAddress.sin_addr));
            
            
            BOOL receivingData = YES;
            NSMutableData *receivedData = [[NSMutableData alloc] init];
            
            while(receivingData){
                
                error = (int)recv(listeningSocket, buffer, MAX_BUFFER_SIZE, 0);
                
                if (error < 0) {
                    
                    NSLog(@"ERROR -- receiving data");
                    receivingData = NO;
                }
                else {
                    
                    NSLog(@"receiving %d bytes of data", error);
                    NSLog(@"buffer contains: %s", buffer);
                    
                    [receivedData appendBytes:buffer length:error];
                    
                    
                    if (error <= MAX_BUFFER_SIZE) {
                        
                        receivingData = NO;
                    }
                }
            }
            
            CFHTTPMessageRef incomingMessage = CFHTTPMessageCreateEmpty(CFAllocatorGetDefault(), TRUE);
            
            UInt8 dataIn[receivedData.length];
            int *dataStart = [receivedData mutableBytes];
            
            memcpy(&dataIn, dataStart, receivedData.length);
            
            NSString *host;
            
            if (!CFHTTPMessageAppendBytes(incomingMessage, dataIn, receivedData.length)) {
                
                NSLog(@"could not deserialize CFHTTPMessage");
            }
            else{
                
                CFDictionaryRef cfHeaders = CFHTTPMessageCopyAllHeaderFields(incomingMessage);
                NSDictionary *headers = (__bridge_transfer NSDictionary*)cfHeaders;
                NSLog(@"server has recieved headers:\n%@", headers);
                
                host = [headers objectForKey:@"Host"];
            }
            
            NSString *serverReadString = [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding];
            NSLog(@"server has read in: %@", serverReadString);
            
            //loop to send/receive data to/from foreign host
            //will process with LFConnection
            
            self.isForeignCommunication = YES;
            self.isConnectedToHost = NO;
            
            while (self.isForeignCommunication) {
                
                if (!self.isConnectedToHost) {
                    
                    self.foreignConnection = [[LFConnection alloc] initWithHostName:host port:(int)[self getForeignPort:host] andProtocol:[self getProtocolForHost:host]];
                    self.foreignConnection.delegate = self;
                    self.foreignConnection.outData = receivedData;
                    [self.foreignConnection connect];
                    self.isConnectedToHost = YES;
                }
            }
            
            NSString *foreignDataString = [[NSString alloc] initWithData:self.foreignInData encoding:NSUTF8StringEncoding];
            NSLog(@"foreign data: %@", foreignDataString);
            
            
            
            
            //testing writing to client
            
            int bufSize = 1024;
            int pos = 0;
            
            NSString *serverResponseString = @"hi there client. This is the server...I'm kinda like your god...Bow before me!!!";
            NSMutableData *serverResponseData = [[serverResponseString dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];
            
            while (pos < serverResponseData.length && error > 0) {
                
                UInt8 *target = [serverResponseData mutableBytes];
                target = target + pos;
                
                int len;
                
                if (serverResponseData.length - pos >= bufSize) {
                    
                    len = bufSize;
                }
                else{
                    
                    len = (int)serverResponseData.length - pos;
                }
                
                UInt8 buffer[len];
                
                memcpy(buffer, target, len);
                
                error = (int)write(listeningSocket, buffer, len);
                
                pos += len;
            }
            
            
            NSLog(@"server running with descriptor: %d", self.localFD);

        }
        
        if (self.localFD != -1) {
            
            close(self.localFD);
        }
    });
}

-(int)getLocalSocketPort{
    
    //NSData *addressData = [self.sockets objectForKey:[NSNumber numberWithInt:self.localFD]];
    struct sockaddr *add = (struct sockaddr*)[self.localAddressData bytes];
    
    return (((struct sockaddr_in*)add)->sin_port);
}


-(NSString*)getServerAddress:(CFSocketRef)socket{
    
    NSData *serverAddressData = (__bridge NSData*)CFSocketCopyAddress(socket);
    struct sockaddr_in *serverAddress = (struct sockaddr_in*)[serverAddressData bytes];
    
    char *ipstr = malloc(INET_ADDRSTRLEN);
    struct in_addr *ipv4addr = &serverAddress->sin_addr;
    ipstr = inet_ntoa(*ipv4addr);
    
    return [NSString stringWithFormat:@"%s", ipstr];
}




- (NSString *)getIPAddress:(BOOL)preferIPv4
{
    NSArray *searchArray = preferIPv4 ?
    @[ IOS_WIFI @"/" IP_ADDR_IPv4, IOS_WIFI @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6 ] :
    @[ IOS_WIFI @"/" IP_ADDR_IPv6, IOS_WIFI @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4 ] ;
    
    NSDictionary *addresses = [self getIPAddresses];
    NSLog(@"addresses: %@", addresses);
    
    __block NSString *address;
    [searchArray enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop)
     {
         address = addresses[key];
         if(address) *stop = YES;
     } ];
    
    return address ? address : @"0.0.0.0";
}

- (NSDictionary *)getIPAddresses
{
    NSMutableDictionary *addresses = [NSMutableDictionary dictionaryWithCapacity:8];
    
    // retrieve the current interfaces - returns 0 on success
    struct ifaddrs *interfaces;
    if(!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        struct ifaddrs *interface;
        for(interface=interfaces; interface; interface=interface->ifa_next) {
            if(!(interface->ifa_flags & IFF_UP) /* || (interface->ifa_flags & IFF_LOOPBACK) */ ) {
                continue; // deeply nested code harder to read
            }
            const struct sockaddr_in *addr = (const struct sockaddr_in*)interface->ifa_addr;
            char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];
            if(addr && (addr->sin_family==AF_INET || addr->sin_family==AF_INET6)) {
                NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
                NSString *type;
                if(addr->sin_family == AF_INET) {
                    if(inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv4;
                    }
                } else {
                    const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;
                    if(inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv6;
                    }
                }
                if(type) {
                    NSString *key = [NSString stringWithFormat:@"%@/%@", name, type];
                    addresses[key] = [NSString stringWithUTF8String:addrBuf];
                }
            }
        }
        // Free memory
        freeifaddrs(interfaces);
    }
    return [addresses count] ? addresses : nil;
}

-(NSInteger)getForeignPort:(NSString*)host{
    
    NSInteger port = -1;
    
    if ([host rangeOfString:@"https"].location != NSNotFound) {
        
        port = 443;
    }
    else if ([host rangeOfString:@"http"].location != NSNotFound){
        
        port = 80;
    }
    
    return port;
}

-(NSString*)getProtocolForHost:(NSString*)host{
    
    NSString *protocol;
    
    if ([host rangeOfString:@"https"].location != NSNotFound) {
        
        protocol = @"https";
    }
    else if ([host rangeOfString:@"http"].location != NSNotFound){
        
        protocol = @"http";
    }
    
    return protocol;
}


#pragma mark - LFConnection Delegate Methods

-(void)connectionHasReceivedData:(LFConnection *)connection{
 
    self.foreignInData = connection.inData;
    self.isForeignCommunication = NO;
    self.isConnectedToHost = NO;
}
@end
