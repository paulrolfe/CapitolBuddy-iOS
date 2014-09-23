//
//  CommDetailsViewController.m
//  MOLegislature 3.0
//
//  Created by Paul Rolfe on 3/15/13.
//  Copyright (c) 2013 Paul Rolfe. All rights reserved.
//

#import "CommDetailsViewController.h"

@interface CommDetailsViewController ()

@end

@implementation CommDetailsViewController
@synthesize currentCommDetail;
@synthesize webView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self setTitle:[NSString stringWithFormat:@"%@ Details",currentCommDetail.commName]];
    
    
    //Create a URL object.
    NSURL *url = [NSURL URLWithString:currentCommDetail.commURL];
    
    //URL Requst Object
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url ];
    
    //Load the request in the UIWebView.
    [webView loadRequest:requestObj];
    [webView setScalesPageToFit:YES];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
// -------------------------------------------------------------------------------
//	setNavigationPaneBarButtonItem:
//  Custom implementation for the navigationPaneBarButtonItem setter.
//  In addition to updating the _navigationPaneBarButtonItem ivar, it
//  reconfigures the toolbar to either show or hide the
//  navigationPaneBarButtonItem.
// -------------------------------------------------------------------------------
- (void)setNavigationPaneBarButtonItem:(UIBarButtonItem *)navigationPaneBarButtonItem
{
    if (navigationPaneBarButtonItem != _navigationPaneBarButtonItem) {
        if (navigationPaneBarButtonItem)
            [self.navigationItem setLeftBarButtonItem: navigationPaneBarButtonItem
                                animated:NO];
        else
            [self.navigationItem setLeftBarButtonItem:nil
                                animated:NO];
    }
    
        _navigationPaneBarButtonItem = navigationPaneBarButtonItem;


}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

@end
