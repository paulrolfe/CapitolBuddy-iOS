//
//  BigNoteCell.h
//  CapitolBuddy
//
//  Created by Paul Rolfe on 4/10/14.
//  Copyright (c) 2014 Paul Rolfe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BigNoteCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *realnameLabel;
@property (weak, nonatomic) IBOutlet UITextView *noteTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *upCountCellLabel;
@property (weak, nonatomic) IBOutlet UILabel *downCountCellLabel;
@property (weak, nonatomic) IBOutlet UIButton *upArrow;
@property (weak, nonatomic) IBOutlet UIButton *downArrow;
@property (weak, nonatomic) IBOutlet UIButton *readOnlyView;
@property (weak, nonatomic) IBOutlet UIButton *sharedButtonView;

-(void)setArrowsVisible:(BOOL)visible;
-(void) resizeCorrectly;

@end
