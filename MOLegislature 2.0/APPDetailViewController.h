//
//  APPDetailViewController.h
//  RSSreader
//
//  Created by Rafael Garcia Leiva on 08/04/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface APPDetailViewController : UIViewController

@property (copy, nonatomic) NSString *url;
@property (copy,nonatomic) NSString *title;
@property (strong, nonatomic) IBOutlet UIWebView *webView;
- (IBAction)fwdButton:(id)sender;
- (IBAction)backButton:(id)sender;


@end
