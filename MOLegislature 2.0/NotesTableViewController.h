//
//  NotesTableViewController.h
//  CapitolBuddy
//
//  Created by Paul Rolfe on 1/19/14.
//  Copyright (c) 2014 Paul Rolfe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Legs.h"
#import "NotesObject.h"
#import "NotesViewController.h"
#import "DataLoader.h"
#import "BigNoteCell.h"

@interface NotesTableViewController : UITableViewController<PFLogInViewControllerDelegate,PFSignUpViewControllerDelegate>{
    NSMutableDictionary * picDic;
    NSString * filePath;
    BOOL notLoggedIn;
    UIButton * logInButton;
    UIView * footerView;

}

@property Legs *currentLegNotes;
@property Legs *currentLegNew;

@property NSMutableArray * allNotes;
@property NSMutableArray * publicNotes;
@property NSMutableArray * myNotes;

@property BOOL shouldReloadNotes;

//but if coming from the menu, load them all and sort by date.

@end
