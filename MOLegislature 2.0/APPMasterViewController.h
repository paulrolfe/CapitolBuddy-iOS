//
//  APPMasterViewController.h
//  RSSreader
//
//  Created by Rafael Garcia Leiva on 08/04/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SideMenuViewController.h"
#import "AppDelegate.h"
#import "DetailViewManager.h"
#import "EditRSSViewController.h"


@interface APPMasterViewController : UITableViewController <NSXMLParserDelegate,UIPopoverControllerDelegate,UISearchBarDelegate, SubstitutableDetailViewController>


@property (nonatomic, strong) UIPopoverController *barButtonItemPopover;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;


- (IBAction)showLeftMenuPressed:(id)sender;

@property (nonatomic, strong) UIBarButtonItem *navigationPaneBarButtonItem;



@end
