//
//  SharingViewController.h
//  CapitolBuddy
//
//  Created by Paul Rolfe on 2/9/14.
//  Copyright (c) 2014 Paul Rolfe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "NotesObject.h"
#import "NotesViewController.h"

@interface SharingViewController : UITableViewController<UIAlertViewDelegate, UISearchDisplayDelegate, UISearchBarDelegate>{
    NSArray *searchResults;
    NSMutableArray *myTeams;
    
    NSMutableArray * currentWriters;
    NSMutableArray * currentReaders;
    NSMutableArray *recentUsers;
    
    NSArray * nilArray;
    
    UITextField* answerField;
    
    PFUser * selectedUser;
    PFRole * selectedRole;
    UserObject * selectedUserObject;
    
    UIImageView * check ;

    
}

@property NotesObject * currentNote;
@property BOOL isManager;
@property NSMutableArray * addedUsers;


@end
