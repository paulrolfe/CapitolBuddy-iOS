//
//  VotesTableViewController.h
//  CapitolBuddy
//
//  Created by Paul Rolfe on 9/23/13.
//  Copyright (c) 2013 Paul Rolfe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VoteTrackers.h"
#import "DataLoader.h"
#import "Legs.h"
#import "DetailViewManager.h"

@interface VotesTableViewController : UITableViewController <SubstitutableDetailViewController>{
    NSMutableArray * billsArray;
}
@property UIStoryboardSegue * mySegue;

- (IBAction)showLeftMenuPressed:(id)sender;
- (IBAction)addButton:(id)sender;
- (IBAction)editButton:(id)sender;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editButtonLabel;

@property (nonatomic, strong) UIBarButtonItem *navigationPaneBarButtonItem;



@end
