//
//  CommDetailsViewController.h
//  MOLegislature 3.0
//
//  Created by Paul Rolfe on 3/15/13.
//  Copyright (c) 2013 Paul Rolfe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CommsClass.h"
#import "DetailViewManager.h"

@interface CommDetailsViewController : UIViewController<SubstitutableDetailViewController>

@property CommsClass * currentCommDetail;
@property (weak, nonatomic) IBOutlet UIWebView *webView;

@property (nonatomic, strong) UIBarButtonItem *navigationPaneBarButtonItem;



@end
