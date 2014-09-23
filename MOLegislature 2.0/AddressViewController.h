//
//  AddressViewController.h
//  CapitolBuddy
//
//  Created by Paul Rolfe on 3/19/14.
//  Copyright (c) 2014 Paul Rolfe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "MyLegsViewController.h"
#import "DetailViewManager.h"
#import "MFSideMenu.h"

@interface AddressViewController : UIViewController<UITextFieldDelegate,SubstitutableDetailViewController>
@property (weak, nonatomic) IBOutlet UITextField *streetLine;
@property (weak, nonatomic) IBOutlet UITextField *cityLine;
@property (weak, nonatomic) IBOutlet UITextField *stateLine;
@property (weak, nonatomic) IBOutlet UITextField *zipLine;
@property BOOL lookUpMode;
- (IBAction)searchButton:(id)sender;
@property (nonatomic, strong) UIBarButtonItem *navigationPaneBarButtonItem;


@end
