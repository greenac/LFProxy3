//
//  LFConnection.m
//  LFProxy3
//
//  Created by Andre Green on 7/16/14.
//  Copyright (c) 2014 Andre Green. All rights reserved.
//

#import "LFConnection.h"
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/types.h>
#include <sys/un.h>
#include <ifaddrs.h>
#include <net/if.h>

@interface LFConnection()

-(void)pairStreams:(CFReadStreamRef*)readStream writeStream:(CFWriteStreamRef*)writeStream;
@end

static NSUInteger const MAX_BUFFER_SIZE = 1024;


@implementation LFConnection

-(id)initWithServerAddressData:(NSData *)addData request:(NSURLRequest *)request protocol:(NSString *)protocol{
    
    self = [super init];
    
    if (self) {
        
        
        _serverAddressData  = addData;
        _hostName           = nil;
        _port               = -1;
        
        _inData             = [[NSMutableData alloc] init];
        _outData            = [[NSMutableData alloc] init];
        
        _bytesRead          = 0;
        _bytesWritten       = 0;
        _protocolType       = protocol.lowercaseString;
        _request            = request;
    }
    
    return self;
}

-(id)initWithHostName:(NSString *)hostName port:(int)port andProtocol:(NSString *)protocol{
    
    self = [super init];
    
    if (self) {
        
        _hostName           = hostName;
        _port               = port;
        
        _inData             = [[NSMutableData alloc] init];
        _outData            = [[NSMutableData alloc] init];
        
        _bytesRead          = 0;
        _bytesWritten       = 0;
        _protocolType       = protocol.lowercaseString;
    }
    
    return self;
}

-(void)connect{
    
    self.outData = [[self dataFromNSURLRequest:self.request] mutableCopy];
    
    CFReadStreamRef inStream;
    CFWriteStreamRef outStream;
    
    if (self.hostName) {
        
        CFStreamCreatePairWithSocketToHost(CFAllocatorGetDefault(), (__bridge CFStringRef)self.hostName, self.port, &inStream, &outStream);
    }
    else{
        
        CFSocketSignature signature = {PF_INET, SOCK_STREAM, IPPROTO_TCP, (__bridge CFDataRef)self.serverAddressData};

        CFStreamCreatePairWithPeerSocketSignature(CFAllocatorGetDefault(), &signature, &inStream, &outStream);
    }
    
    //[self setProxyInfoForReadStream:&inStream andWriteStream:&outStream];
    
    NSRunLoop *currentLoop = [NSRunLoop currentRunLoop];
    
    self.inputStream = (__bridge_transfer NSInputStream*)inStream;
    self.inputStream.delegate = self;
    [self.inputStream scheduleInRunLoop:currentLoop forMode:NSDefaultRunLoopMode];
    [self.inputStream open];

    self.outputStream = (__bridge_transfer NSOutputStream*)outStream;
    self.outputStream.delegate = self;
    [self.outputStream scheduleInRunLoop:currentLoop forMode:NSDefaultRunLoopMode];
    [self.outputStream open];
    
    [currentLoop run];
}

-(void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode{
    
    NSLog(@"event code: %lu", eventCode);
    
    switch (eventCode) {

        case NSStreamEventOpenCompleted:
            NSLog(@"stream event open completed");
            break;
            
        case NSStreamEventHasSpaceAvailable:{
            
            NSLog(@"stream event has space available");
            
            if (stream == self.outputStream) {
                
                NSInteger byteDifference = self.outData.length - self.bytesWritten;
                
                if (byteDifference > 0) {
                    
                    uint8_t *byteMarker = (uint8_t*)[[self.outData mutableCopy] mutableBytes];
                    *byteMarker += self.bytesWritten;
                                        
                    NSUInteger size = (byteDifference < MAX_BUFFER_SIZE) ? byteDifference : MAX_BUFFER_SIZE;
                    
                    UInt8 buffer[size];
                    
                    memcpy(buffer, byteMarker, size);
                    
                    [self.outputStream write:buffer maxLength:size];
                    
                    self.bytesWritten += size;
                }
            }

            break;
        }
            
        case NSStreamEventHasBytesAvailable:{
            NSLog(@"stream has bytes available");
            
            if (stream == self.inputStream) {
                
                NSLog(@"input stream has bytes available");

                UInt8 buffer[MAX_BUFFER_SIZE];
                NSUInteger len = 0;
                
                len = [self.inputStream read:buffer maxLength:MAX_BUFFER_SIZE];
                
                if (len) {
                    
                    [self.inData appendBytes:buffer length:len];
                    self.bytesRead += len;
                    
                    NSString *inString = [[NSString alloc] initWithData:self.inData encoding:NSUTF8StringEncoding];
                    NSLog(@"data read in from connection: %@", inString);
                }
                else{
                    
                    NSLog(@"Input stream not reading. length: %lu", (unsigned long)len);
                }
            }
            
            break;
        }
        
        case NSStreamEventEndEncountered:{
            
            NSLog(@"end of event encountered");
            
            if (stream == self.outputStream) {
                NSLog(@"closing output stream");
                
                self.bytesWritten = 0;
            }
            else if (stream == self.inputStream) {
                
                NSLog(@"closing input stream");
                
                if ([self.delegate respondsToSelector:@selector(connectionHasReceivedData:)]) {
                    
                    [self.delegate connectionHasReceivedData:self];
                }
                
                self.bytesRead = 0;
                self.inData.length = 0;
            }
            
            [stream close];
            [stream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            
            break;
        }
        
        case NSStreamEventErrorOccurred:{
            
            NSLog(@"stream error occured");
            NSString* errorMessage = [NSString stringWithFormat:@"%@ (Code = %ld)", [stream.streamError localizedDescription], (long)[stream.streamError code]];
            NSLog(@"%@", errorMessage);
            break;
        }
        
        case NSStreamEventNone:
            NSLog(@"stream event none");
            break;
            
        default:
            NSLog(@"hit default case in LFConnection");
            break;
    }
}


-(void)setProxyInfoForReadStream:(CFReadStreamRef *)readStream andWriteStream:(CFWriteStreamRef *)writeStream{
    
    // create proxy setting
    NSString *host = (NSString *)kCFStreamPropertyHTTPProxyHost;
    NSString *port = (NSString *)kCFStreamPropertyHTTPProxyPort;
    
    if ([self.protocolType isEqualToString:@"https"]) {
        
        host = (NSString *)kCFStreamPropertyHTTPSProxyHost;
        port = (NSString *)kCFStreamPropertyHTTPSProxyPort;
    }
    
    // apply settings
    CFWriteStreamSetProperty(*writeStream, (__bridge CFStringRef)host, (__bridge CFStringRef)[self serverAddress]);
    CFWriteStreamSetProperty(*writeStream, (__bridge CFStringRef)port, (__bridge CFNumberRef)[self serverPort]);
    
    CFReadStreamSetProperty(*readStream, (__bridge CFStringRef)host, (__bridge CFStringRef)[self serverAddress]);
    CFReadStreamSetProperty(*readStream, (__bridge CFStringRef)port, (__bridge CFNumberRef)[self serverPort]);
}

-(NSData*)dataFromNSURLRequest:(NSURLRequest*)request{
    
    //copy request into CFHTTPMessage
    
    CFHTTPMessageRef message = CFHTTPMessageCreateRequest(CFAllocatorGetDefault(),
                                                           (__bridge CFStringRef)request.HTTPMethod,
                                                           (__bridge CFURLRef)request.URL.absoluteURL,
                                                           kCFHTTPVersion1_1);

    if (request.HTTPBody.length > 0) {
        
        CFHTTPMessageSetBody(message, (__bridge CFDataRef)request.HTTPBody);
    }
    
    for (NSString *key in request.allHTTPHeaderFields) {
        
        NSString *value = [request.allHTTPHeaderFields objectForKey:key];
        CFHTTPMessageSetHeaderFieldValue(message, (__bridge CFStringRef)key, (__bridge CFStringRef)value);
    }
    
    NSString *host = @"Host";
    
    CFHTTPMessageSetHeaderFieldValue(message, (__bridge CFStringRef)host, (__bridge CFStringRef)request.URL.absoluteString);
    
    CFHTTPMessageSetHeaderFieldValue(message, CFSTR("Lotus-Flare-Header"), CFSTR("Test-Header"));
    
    CFDataRef messageCFData = CFHTTPMessageCopySerializedMessage(message);
    
    NSData *messageData = (__bridge_transfer NSData*)messageCFData;

    return messageData;
}

-(NSNumber*)serverPort{
    
    struct sockaddr *add = (struct sockaddr*)[self.serverAddressData bytes];
    int port = (((struct sockaddr_in*)add)->sin_port);
    
    return [NSNumber numberWithInt:port];
}


-(NSString*)serverAddress{
    
    struct sockaddr_in *serverAddress = (struct sockaddr_in*)[self.serverAddressData bytes];
    
    char *ipstr = malloc(INET_ADDRSTRLEN);
    struct in_addr *ipv4addr = &serverAddress->sin_addr;
    ipstr = inet_ntoa(*ipv4addr);
    
    return [NSString stringWithFormat:@"%s", ipstr];
}

@end
