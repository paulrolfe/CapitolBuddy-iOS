//
//  AddFeedViewController.h
//  CapitolBuddy
//
//  Created by Paul Rolfe on 12/21/13.
//  Copyright (c) 2013 Paul Rolfe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EditRSSViewController.h"

@interface AddFeedViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *titleTextInput;
@property (weak, nonatomic) IBOutlet UITextField *urlTextInput;
- (IBAction)addFeedButton:(id)sender;
- (IBAction)cancelButton:(id)sender;

@property NSString * currentTitles;
@property NSString * currentURLs;

@end
