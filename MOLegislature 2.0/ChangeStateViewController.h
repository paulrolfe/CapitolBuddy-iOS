//
//  ChangeStateViewController.h
//  CapitolBuddy
//
//  Created by Paul Rolfe on 9/11/13.
//  Copyright (c) 2013 Paul Rolfe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "AppDelegate.h"

@interface ChangeStateViewController : UITableViewController <PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate, MFMailComposeViewControllerDelegate, UIAlertViewDelegate>{
    UITextField * answerField;
    BOOL npoON;
}

- (void)reload;
- (IBAction)backButtonForiPad:(id)sender;
- (IBAction)couponCodeButton:(id)sender;

@end
