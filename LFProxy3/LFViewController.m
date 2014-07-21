//
//  LFViewController.m
//  LFProxy3
//
//  Created by Andre Green on 7/16/14.
//  Copyright (c) 2014 Andre Green. All rights reserved.
//

#import "LFViewController.h"
#import "LFLocalProxyServer.h"
#import "LFConnection.h"


@interface LFViewController ()

@end

@implementation LFViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    
	self.signatures = [[NSMutableArray alloc] init];
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)makeConnection:(id)sender {
    
    NSURL *url = [NSURL URLWithString:@"http://www.google.com"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    [self.webview loadRequest:request];
    
    NSURL *url1 = [NSURL URLWithString:@"http://www.yahoo.com"];
    NSURLRequest *request1 = [NSURLRequest requestWithURL:url1];
    
    //[self.webview1 loadRequest:request1];
    
}


@end
