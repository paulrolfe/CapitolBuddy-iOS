//
//  InfoViewController.h
//  MOLegislature 2.0
//
//  Created by Paul Rolfe on 2/26/13.
//  Copyright (c) 2013 Paul Rolfe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DataLoader.h"
#import "AppDelegate.h"
#import "NotesTableViewController.h"
#import "DetailViewManager.h"
#import "APPDetailViewController.h"
#import "SubmitCorrectionViewController.h"


@interface InfoViewController : UIViewController <SubstitutableDetailViewController>


@property (strong, nonatomic) Legs *currentLeg;
@property (weak, nonatomic) IBOutlet UIImageView *currentImage;
@property (weak, nonatomic) IBOutlet UILabel *currentDistrict;
@property (weak, nonatomic) IBOutlet UILabel *currentParty;

@property (weak, nonatomic) IBOutlet UITextView *currentEmail;



@property (weak, nonatomic) IBOutlet UIButton *currentPhone;
- (IBAction)phoneAction:(id)sender;


- (IBAction)websiteAction:(id)sender;
- (IBAction)recentNewsAction:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *suggestCorrectionView;
- (IBAction)suggestCorrectionAction:(id)sender;


@property (weak, nonatomic) IBOutlet UILabel *currentHometown;
@property (weak, nonatomic) IBOutlet UITextView *currentOffice;
@property (weak, nonatomic) IBOutlet UITextView *currentBio;
@property (weak, nonatomic) IBOutlet UITextView *currentComms;
@property (weak, nonatomic) IBOutlet UILabel *currentStaff;


@property (nonatomic,retain) NSString *homeDir;
@property (nonatomic,retain) NSFileManager *fileMgr;

@property (nonatomic, strong) UIBarButtonItem *navigationPaneBarButtonItem;

-(NSString *) GetDocumentDirectory;

- (IBAction)backToVotesButton:(id)sender;
@property UIBarButtonItem * backButton;



@end
