//
//  AllNotesViewController.h
//  CapitolBuddy
//
//  Created by Paul Rolfe on 2/19/14.
//  Copyright (c) 2014 Paul Rolfe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "DetailViewManager.h"
#import "MFSideMenu.h"
#import "NotesObject.h"
#import "NotesViewController.h"
#import "TeamManagerViewController.h"
#import "SideMenuViewController.h"
#import "BigNoteCell.h"

@interface AllNotesViewController : UIViewController <UIPopoverControllerDelegate, SubstitutableDetailViewController, UITableViewDataSource, UITableViewDelegate, UITabBarDelegate, UISearchBarDelegate, UISearchDisplayDelegate, UIAlertViewDelegate, PFSignUpViewControllerDelegate, PFLogInViewControllerDelegate>{
    NSMutableArray * allNotes;
    NSMutableArray * notesToDisplay;
    NSMutableArray * newNotes;
    NSMutableArray * notesTeamToDisplay;
    NSMutableArray * myNotes;
    NSMutableArray * publicNotes;
    
    NSMutableArray * searchResults;
    
    NSMutableDictionary * picDic;
    NSString * filePath;

    NSMutableArray * teams;
    NSMutableArray * teamCount;
    PFRole * team;

    UIView * footerView;
    NSInteger loadingThreshold;
}

@property (nonatomic, strong) UIPopoverController *barButtonItemPopover;
@property (nonatomic, strong) UIBarButtonItem *navigationPaneBarButtonItem;

- (IBAction)showLeftMenuPressed:(id)sender;
@property (weak, nonatomic) IBOutlet UITabBar *notesTabBar;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControlBar;
@property (weak, nonatomic) IBOutlet UITableView *tableview;
@property BOOL shouldReloadNotes;

@property int badgeCount;

@property UIRefreshControl * refreshControl;



@end
