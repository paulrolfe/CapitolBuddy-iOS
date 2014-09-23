//
//  MemberTableViewController.h
//  MOLegislature 2.0
//
//  Created by Paul Rolfe on 2/26/13.
//  Copyright (c) 2013 Paul Rolfe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "InfoViewController.h"
#import "CommTableViewController.h"
#import "Legs.h"
#import "DataLoader.h"
#import "CommDetailsViewController.h"
#import "DetailViewManager.h"

@interface MemberTableViewController : UITableViewController

@property CommsClass * currentComm;

@property (nonatomic,retain) NSString *homeDir;
@property (nonatomic,retain) NSFileManager *fileMgr;

- (IBAction)infoButton:(id)sender;

-(NSString *) GetDocumentDirectory;


@end
