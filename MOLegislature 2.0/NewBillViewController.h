//
//  NewBillViewController.h
//  CapitolBuddy
//
//  Created by Paul Rolfe on 9/24/13.
//  Copyright (c) 2013 Paul Rolfe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NewBillViewController : UIViewController
- (IBAction)cancelButton:(id)sender;
- (IBAction)addBillButton:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *addedBillName;

- (IBAction)segmentedHouseSenate:(id)sender;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentOutlet;

@end
