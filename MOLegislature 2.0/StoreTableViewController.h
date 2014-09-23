//
//  StoreTableViewController.h
//  CapitolBuddy
//
//  Created by Paul Rolfe on 5/1/14.
//  Copyright (c) 2014 Paul Rolfe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "AppDelegate.h"
#import "StatesClass.h"

@interface StoreTableViewController : UITableViewController <PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate, MFMailComposeViewControllerDelegate, UIAlertViewDelegate>{
    UITextField * answerField;
    NSMutableArray *_products;
    NSMutableArray *_purchasedProducts;
    BOOL npoON;
    BOOL freeON;
}

- (void)reload;
- (IBAction)backButtonForiPad:(id)sender;
- (IBAction)couponCodeButton:(id)sender;

@end
