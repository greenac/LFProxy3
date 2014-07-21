//
//  LFViewController.h
//  LFProxy3
//
//  Created by Andre Green on 7/16/14.
//  Copyright (c) 2014 Andre Green. All rights reserved.
//

#import <UIKit/UIKit.h>
@class LFLocalProxyServer, LFConnection;

@interface LFViewController : UIViewController


@property(nonatomic, strong)UIActivityIndicatorView *activityIndicator;
@property(nonatomic, strong)LFLocalProxyServer *server;
@property(nonatomic, strong)LFConnection *connection;
@property(nonatomic, copy)NSMutableArray *signatures;
@property (weak, nonatomic) IBOutlet UIWebView *webview;
@property (weak, nonatomic) IBOutlet UIWebView *webview1;

- (IBAction)makeConnection:(id)sender;


@end
