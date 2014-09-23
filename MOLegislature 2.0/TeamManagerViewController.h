//
//  TeamManagerViewController.h
//  CapitolBuddy
//
//  Created by Paul Rolfe on 2/13/14.
//  Copyright (c) 2014 Paul Rolfe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "AddUsersViewController.h"
#import "DetailViewManager.h"
#import "MFSideMenu.h"

@interface TeamManagerViewController : UITableViewController<UIAlertViewDelegate,SubstitutableDetailViewController>{
    
    NSMutableArray * managedTeams;
    NSMutableArray * otherTeams;
    NSMutableArray * managedTeamCount;
    NSMutableArray * otherTeamCount;
    
    UIView * footerView;
    
    UITextField* answerField;
    
    PFRole * roleToEdit;
    
    BOOL loggedIn;
}
@property (nonatomic, strong) UIBarButtonItem *navigationPaneBarButtonItem;


@end
