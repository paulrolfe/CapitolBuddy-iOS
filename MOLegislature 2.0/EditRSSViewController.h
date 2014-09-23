//
//  EditRSSViewController.h
//  CapitolBuddy
//
//  Created by Paul Rolfe on 12/20/13.
//  Copyright (c) 2013 Paul Rolfe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "AddFeedViewController.h"

@interface EditRSSViewController : UITableViewController

- (IBAction)backButton:(id)sender;

@property NSArray * feedURLs;
@property NSArray * feedTitles;

@end
