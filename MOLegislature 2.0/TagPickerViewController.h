//
//  TagPickerViewController.h
//  CapitolBuddy
//
//  Created by Paul Rolfe on 2/7/14.
//  Copyright (c) 2014 Paul Rolfe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NotesObject.h"
#import "Legs.h"
#import "DataLoader.h"
#import "NotesViewController.h"

@interface TagPickerViewController : UITableViewController<UISearchBarDelegate,UISearchDisplayDelegate,UITableViewDelegate,UITableViewDataSource> {
    NSArray *searchResults;

}

@property NotesObject * currentNote;
@property BOOL isManager;

@end
