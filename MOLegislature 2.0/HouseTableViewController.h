//
//  HouseTableViewController.h
//  MOLegislature 2.0
//
//  Created by Paul Rolfe on 2/26/13.
//  Copyright (c) 2013 Paul Rolfe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "InfoViewController.h"
#import "DataLoader.h"
#import "Legs.h"
#import "AppDelegate.h"
#import "DetailViewManager.h"


@interface HouseTableViewController : UITableViewController<UIPopoverControllerDelegate>{
    NSArray *reloadedReps;
}

@property NSArray *representatives;
/*
- (IBAction)notesRefresh:(id)sender;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *buttonTitle;
 */

- (IBAction)showLeftMenuPressed:(id)sender;
@property (nonatomic, strong) UIPopoverController *barButtonItemPopover;


@property (nonatomic,retain) NSString *homeDir;
@property (nonatomic,retain) NSFileManager *fileMgr;

-(NSString *) GetDocumentDirectory;

@end