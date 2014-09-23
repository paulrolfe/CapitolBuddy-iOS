//
//  EditProfileViewController.h
//  CapitolBuddy
//
//  Created by Paul Rolfe on 1/15/14.
//  Copyright (c) 2014 Paul Rolfe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <MessageUI/MessageUI.h>
#import "TeamManagerViewController.h"

@interface EditProfileViewController : UIViewController <UIAlertViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate, UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UITextField *userNameField;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;

- (IBAction)resetPswdButton:(id)sender;
- (IBAction)dismissKeyboard:(id)sender;

@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *orgField;
@property (weak, nonatomic) IBOutlet UIImageView *imageProfile;

- (IBAction)saveProfile:(id)sender;
- (IBAction)uploadPhoto:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *uploadButton;

@property (weak, nonatomic) IBOutlet UIButton *editTeamsView;
- (IBAction)editTeamsButton:(id)sender;

@end
