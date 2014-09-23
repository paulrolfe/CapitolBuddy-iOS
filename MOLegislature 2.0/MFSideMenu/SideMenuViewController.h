//
//  SideMenuViewController.h
//  MFSideMenuDemoStoryboard
//
//  Created by Michael Frederick on 5/7/13.
//  Copyright (c) 2013 Michael Frederick. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DetailViewManager.h"
#import "OptionsViewController.h"
#import "NewMapViewController.h"
#import "NotesObject.h"
#import "AllNotesViewController.h"
#import "AddressViewController.h"
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

@interface SideMenuViewController : UITableViewController<UIPopoverControllerDelegate, UISplitViewControllerDelegate, UIAlertViewDelegate, MFMailComposeViewControllerDelegate,ABPeoplePickerNavigationControllerDelegate>{
    NSString * email;
    NSMutableArray * newNotes;
    UIImageView * check ;
}

@property (nonatomic, strong) UIPopoverController *barButtonItemPopover;
@property (nonatomic, strong) DetailViewManager *detailViewManager;

@property (weak, nonatomic) IBOutlet UINavigationBar *titleBar;
- (IBAction)inviteButton:(id)sender;
- (IBAction)rateButton:(id)sender;
- (IBAction)supportTapped:(id)sender;

@property int noteAlertCount;

-(void) loadNoteBadge;


@end
