//
//  ShareActions.h
//  CapitolBuddy
//
//  Created by Paul Rolfe on 4/25/14.
//  Copyright (c) 2014 Paul Rolfe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "NotesObject.h"
#import "NotesViewController.h"

@interface ShareActions : UIActionSheet <UIActionSheetDelegate>

@property (strong) NotesObject *item;
@property (strong) UIViewController *rootViewController;
@property NSString * messageTitle;
@property NSString * messageBody;


+ (instancetype)actionSheetForItem:(NotesObject *)item;

@end
