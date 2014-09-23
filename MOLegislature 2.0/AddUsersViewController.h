//
//  AddUsersViewController.h
//  CapitolBuddy
//
//  Created by Paul Rolfe on 2/13/14.
//  Copyright (c) 2014 Paul Rolfe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "NotesObject.h"

@interface AddUsersViewController : UITableViewController<UIAlertViewDelegate, UISearchDisplayDelegate, UISearchBarDelegate>{
    NSArray *searchResults;
    
    NSMutableArray * currentMembers;
    NSMutableArray * currentManagers;
    NSMutableArray *recentUsers;
    
    NSArray * nilArray;
    
    UITextField* answerField;
    
    PFUser * selectedUser;
    UserObject * selectedUserObject;
    
    UIImageView * check ;

    
}
@property PFRole * currentRole;
@property BOOL isManager;

-(IBAction)savePFRole:(id)sender;
@property UIBarButtonItem * saveButtonView;

@end
