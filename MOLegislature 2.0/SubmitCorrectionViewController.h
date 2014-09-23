//
//  SubmitCorrectionViewController.h
//  CapitolBuddy
//
//  Created by Paul Rolfe on 4/24/14.
//  Copyright (c) 2014 Paul Rolfe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "Legs.h"

@interface SubmitCorrectionViewController : UIViewController<UITextViewDelegate,UIPickerViewDelegate,UIPickerViewDataSource>{
    NSArray * fieldArray;
    UIView *firstResponder;
    CGRect originalTextViewFrame;

}
- (IBAction)backButton:(id)sender;
- (IBAction)keyboardCancelButton:(id)sender;
@property (weak, nonatomic) IBOutlet UIPickerView *fieldPicker;
@property (weak, nonatomic) IBOutlet UITextView *commentField;
- (IBAction)submitButton:(id)sender;

@property Legs * currentLeg;

@end
