//
//  CommTableViewController.h
//  MOLegislature 2.0
//
//  Created by Paul Rolfe on 2/26/13.
//  Copyright (c) 2013 Paul Rolfe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MemberTableViewController.h"
#import "Legs.h"
#import "DataLoader.h"

@interface CommTableViewController : UITableViewController<UIPopoverControllerDelegate>
- (IBAction)showLeftMenuPressed:(id)sender;
@property (nonatomic, strong) UIPopoverController *barButtonItemPopover;



@end
