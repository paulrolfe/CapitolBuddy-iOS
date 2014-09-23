//
//  TallyViewController.h
//  CapitolBuddy
//
//  Created by Paul Rolfe on 9/24/13.
//  Copyright (c) 2013 Paul Rolfe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "VoteTrackers.h"
#import "DataLoader.h"
#import "Legs.h"

@interface TallyViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *GoodVotesLabel;
@property (weak, nonatomic) IBOutlet UILabel *BadVotesLabel;
@property (weak, nonatomic) IBOutlet UILabel *SwingVotesLabel;

@property VoteTrackers * thisBill;
@property NSArray * LegislatorsAll;

@property (weak, nonatomic) IBOutlet UINavigationBar *navBarTitle;
- (IBAction)backButton:(id)sender;

- (void)refreshData;
- (IBAction)dAdderGood:(id)sender;
- (IBAction)rAdderGood:(id)sender;

- (IBAction)dAdderBad:(id)sender;
- (IBAction)rAdderBad:(id)sender;

- (IBAction)oneTwoAdderGood:(id)sender;
- (IBAction)fourFiveAdderGood:(id)sender;

- (IBAction)oneTwoAdderBad:(id)sender;
- (IBAction)fourFiveAdderBad:(id)sender;

- (IBAction)threeAdderSwing:(id)sender;


@end
