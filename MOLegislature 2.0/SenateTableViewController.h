//
//  SenateTableViewController.h
//  MOLegislature 2.0
//
//  Created by Paul Rolfe on 2/26/13.
//  Copyright (c) 2013 Paul Rolfe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "InfoViewController.h"
#import "DataLoader.h"
#import "Legs.h"
#import "StateIAPHelper.h"
#import "AppDelegate.h"
#import "DetailViewManager.h"
#import "NotesObject.h"

@class InfoViewController;

@interface SenateTableViewController : UITableViewController <UIAlertViewDelegate,PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate, UIPopoverControllerDelegate>{
    NSArray *searchResults;
    NSArray *reloadedSens;
}
@property (nonatomic, strong) UIPopoverController *barButtonItemPopover;


@property NSArray *senators;
/*
- (IBAction)notesRefresh:(id)sender;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *buttonTitle;
 */

- (IBAction)showLeftMenuPressed:(id)sender;

@property (nonatomic,retain) NSString *homeDir;
@property (nonatomic,retain) NSFileManager *fileMgr;

-(NSString *) GetDocumentDirectory;

@end