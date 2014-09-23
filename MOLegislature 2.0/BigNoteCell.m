//
//  BigNoteCell.m
//  CapitolBuddy
//
//  Created by Paul Rolfe on 4/10/14.
//  Copyright (c) 2014 Paul Rolfe. All rights reserved.
//

#import "BigNoteCell.h"

@implementation BigNoteCell
@synthesize usernameLabel=_usernameLabel;
@synthesize profileImageView=_profileImageView;
@synthesize realnameLabel=_realnameLabel;
@synthesize noteTextLabel=_noteTextLabel;
@synthesize timeLabel=_timeLabel;
@synthesize upCountCellLabel=_upCountCellLabel;
@synthesize downCountCellLabel=_downCountCellLabel;
@synthesize upArrow=_upArrow;
@synthesize downArrow=_downArrow;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
    }
    return self;
}

-(void) resizeCorrectly{
    [self.usernameLabel sizeToFit];
    [self.realnameLabel sizeToFit];
    [self.realnameLabel setFrame:CGRectMake(self.usernameLabel.frame.origin.x+self.usernameLabel.frame.size.width, self.realnameLabel.frame.origin.y, self.realnameLabel.frame.size.width, self.realnameLabel.frame.size.height)];
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
-(void)setArrowsVisible:(BOOL)visible{
    if(visible){
        [self.upArrow setHidden:NO];
        [self.downArrow setHidden:NO];
        [self.upCountCellLabel setHidden:NO];
        [self.downCountCellLabel setHidden:NO];
    }
    if(!visible){
        [self.upArrow setHidden:YES];
        [self.downArrow setHidden:YES];
        [self.upCountCellLabel setHidden:YES];
        [self.downCountCellLabel setHidden:YES];
    }
}

@end
