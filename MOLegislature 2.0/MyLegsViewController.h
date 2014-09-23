//
//  MyLegsViewController.h
//  CapitolBuddy
//
//  Created by Paul Rolfe on 3/20/14.
//  Copyright (c) 2014 Paul Rolfe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DataLoader.h"
#import "Legs.h"
#import "AddressViewController.h"
#import "InfoViewController.h"


@interface MyLegsViewController : UITableViewController<UIAlertViewDelegate,PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate, UIPopoverControllerDelegate>
@property (nonatomic, strong) UIPopoverController *barButtonItemPopover;

@property BOOL lookUpMode;

@property NSString * lookedUpSen;
@property NSString * lookedUpRep;
@property NSString * lookedUpState;

- (IBAction)showLeftMenuPressed:(id)sender;


@end
