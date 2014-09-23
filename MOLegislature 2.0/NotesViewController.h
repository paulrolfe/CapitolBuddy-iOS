//
//  NotesViewController.h
//  MOLegislature 3.0
//
//  Created by Paul Rolfe on 3/10/13.
//  Copyright (c) 2013 Paul Rolfe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <Parse/Parse.h>
#import "Legs.h"
#import "DataLoader.h"
#import "InfoViewController.h"
#import "DetailViewManager.h"
#import "NotesObject.h"
#import "TagPickerViewController.h"
#import "SharingViewController.h"
#import "ShareActions.h"

@class NotesTableViewController;
@class AllNotesViewController;

@interface NotesViewController : UIViewController <UITextViewDelegate, UINavigationBarDelegate,SubstitutableDetailViewController, UIAlertViewDelegate, UIWebViewDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate>{
    BOOL didSave;
    UIActivityIndicatorView * spinnner;
}

@property (strong, nonatomic) IBOutlet UIBarButtonItem *buttonView;

@property Legs *currentLegNotes;
@property NotesObject *currentNoteObject;
@property (weak, nonatomic) IBOutlet UITextView *currentNotes;
@property (weak, nonatomic) IBOutlet UILabel *saveDateLabel;


- (IBAction)saveButton:(id)sender;
@property (weak, nonatomic) IBOutlet UIBarButtonItem * saveButtonView;

@property (weak, nonatomic) IBOutlet UILabel *publicLabel;
@property (weak, nonatomic) IBOutlet UISwitch *publicSwitchOutlet;
- (IBAction)publicSwitchAction:(id)sender;
@property (weak, nonatomic) IBOutlet UIView *publicToolBar;
@property (weak, nonatomic) IBOutlet UIButton *upVoteView;
@property (weak, nonatomic) IBOutlet UIButton *downVoteView;
@property (weak, nonatomic) IBOutlet UIButton *flagButtonView;
- (IBAction)upVoteAction:(id)sender;
- (IBAction)downVoteAction:(id)sender;
- (IBAction)flagButtonAction:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *upCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *downCountLabel;
@property (weak, nonatomic) IBOutlet UIButton *publicExplainButtonView;
- (IBAction)publicExplainButtonAction:(id)sender;



@property (weak, nonatomic) IBOutlet UILabel *starCount;
- (IBAction)starSlider:(id)sender;
@property (weak, nonatomic) IBOutlet UISlider *starSlidePosition;
@property (weak, nonatomic) IBOutlet UIImageView *starImage;

@property (nonatomic, strong) UIBarButtonItem *navigationPaneBarButtonItem;
@property (weak, nonatomic) IBOutlet UINavigationItem *navBar;

- (IBAction)editTextButton:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *editTextButton;
@property (weak, nonatomic) IBOutlet UIButton *shareButtonText;
- (IBAction)shareButtonClicked:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *tagsButtonView;
- (IBAction)tagsButtonAction:(id)sender;

@property NSMutableArray * addedUsers;
@property NotesTableViewController * ntvc;
@property AllNotesViewController * antvc;

-(NSString *)getLegislatorNameFromTagArray;

@end
