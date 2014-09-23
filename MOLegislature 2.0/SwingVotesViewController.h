//
//  SwingVotesViewController.h
//  CapitolBuddy
//
//  Created by Paul Rolfe on 9/24/13.
//  Copyright (c) 2013 Paul Rolfe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VotesTableViewController.h"
#import "Legs.h"

@interface SwingVotesViewController : UITableViewController

@property VoteTrackers * thisBill;
@property NSArray * LegislatorsAll;

- (void)refreshData;
- (IBAction)backButton:(id)sender;

@end
