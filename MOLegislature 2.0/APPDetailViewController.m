//
//  APPDetailViewController.m
//  RSSreader
//
//  Created by Rafael Garcia Leiva on 08/04/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import "APPDetailViewController.h"
#import "SenateTableViewController.h"

@implementation APPDetailViewController

#pragma mark - Managing the detail item

- (void)viewDidLoad {
    [super viewDidLoad];
    //NSURL *myURL = [NSURL URLWithString: [self.url stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];

    
    NSURL *myURL = [NSURL URLWithString:[self.url stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    //NSURL * betterURL = [myURL standardizedURL];

    
    NSURLRequest *request = [NSURLRequest requestWithURL:myURL];
    [self.webView loadRequest:request];
    self.webView.scalesPageToFit=YES;
    
    if (self.presentingViewController){
        UIBarButtonItem * backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(backActionOptional)];
        self.navigationItem.leftBarButtonItem = backButton;
    }
    
}

- (IBAction)saveToLeg:(id)sender {
    //Make the legislators screen pop up and when you select a legislator a popup appears... "Would you like to save this link to [legislator name]'s notes?"
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
    UITabBarController *destNav = [storyboard instantiateViewControllerWithIdentifier:@"MainTabBar"];
    
    NSString *currentURL = [[[self.webView request] URL] absoluteString];
    
    [[NSUserDefaults standardUserDefaults] setObject:currentURL forKey:@"viewForLinkSave"];
    
    [self presentViewController:destNav animated:YES completion:nil];


}

- (IBAction)fwdButton:(id)sender {
    [self.webView goForward];
}

- (IBAction)backButton:(id)sender {
    [self.webView goBack];
}

//this back button is displayed iff coming from Recent News link.
- (void)backActionOptional {
    [self dismissViewControllerAnimated:YES completion:nil];
    
        
}
@end
