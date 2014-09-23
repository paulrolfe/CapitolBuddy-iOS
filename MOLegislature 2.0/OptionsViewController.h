//
//  OptionsViewController.h
//  MOLegislature 3.0
//
//  Created by Paul Rolfe on 3/23/13.
//  Copyright (c) 2013 Paul Rolfe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <Parse/Parse.h>
#import "Legs.h"
#import "DataLoader.h"
#import "DetailViewManager.h"


@interface OptionsViewController : UIViewController <PFLogInViewControllerDelegate,PFSignUpViewControllerDelegate,SubstitutableDetailViewController>
@property (weak, nonatomic) IBOutlet UILabel *loadedStateLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentUserLabel;
@property (weak, nonatomic) IBOutlet UIButton *editProfileButtonView;

- (IBAction)logOutButton:(id)sender;
- (IBAction)showLeftMenuPressed:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *logOutText;

@property (nonatomic, strong) UIBarButtonItem *navigationPaneBarButtonItem;

@end
