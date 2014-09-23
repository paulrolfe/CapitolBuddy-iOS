//
//  EditProfileViewController.m
//  CapitolBuddy
//
//  Created by Paul Rolfe on 1/15/14.
//  Copyright (c) 2014 Paul Rolfe. All rights reserved.
//

#import "EditProfileViewController.h"

@interface EditProfileViewController ()

@end

@implementation EditProfileViewController
@synthesize nameField,emailField,orgField,imageProfile,userNameField,dateLabel,uploadButton;

UITextField* answerField;
CGRect originalTextViewFrame;
UIView *firstResponder;
BOOL changedImage;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    changedImage=NO;
    [[PFUser currentUser] fetchInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        userNameField.text=[PFUser currentUser].username;
        emailField.text=[PFUser currentUser].email;
        nameField.text=[[PFUser currentUser] objectForKey:@"realName"];
        nameField.autocapitalizationType=UITextAutocapitalizationTypeWords;
        orgField.text=[[PFUser currentUser] objectForKey:@"realOrg"];
        orgField.autocapitalizationType=UITextAutocapitalizationTypeWords;
        
        NSDate *time=[PFUser currentUser].createdAt;
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"MM'/'dd'/'yyyy"];
        NSString *strTime = [formatter stringFromDate:time];
        dateLabel.text=[NSString stringWithFormat:@"Signup Date: %@",strTime];
        
        //load pffile and set it
        PFFile *userImageFile = [[PFUser currentUser]objectForKey:@"imageFile"];
        [userImageFile getDataInBackgroundWithBlock:^(NSData *imageData, NSError *error) {
            if (!error) {
                UIImage *image = [UIImage imageWithData:imageData];
                imageProfile.image = image;
                [self reloadInputViews];
            }
        }];

    }];

    originalTextViewFrame = self.view.frame;
    
    // Register notifications for when the keyboard appears
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"v1.6FirstTime"]){
        UIAlertView * newProfile = [[UIAlertView alloc] initWithTitle:@"Make a profile" message:@"Completing your profile will make sharing notes with colleagues easier." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [newProfile show];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"v1.6FirstTime"];//Yes, it has loaded for the first time.
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    if([PFAnonymousUtils isLinkedWithUser:[PFUser currentUser]]){//if they are not anonymous, go back.
        UIAlertView * newProfile = [[UIAlertView alloc] initWithTitle:@"Please log-in first" message:@"Anonymous users cannot update their profiles. Please log-in or sign-up first." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [newProfile show];
    }
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)resetPswdButton:(id)sender {
    
    //put up an alert view.
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:@"Current Password Needed"
                          message:@"Please enter your current password."
                          delegate:self
                          cancelButtonTitle: nil
                          otherButtonTitles:@"Continue", @"Cancel",nil ];
    
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    alert.tag=56;
    answerField = [alert textFieldAtIndex:0];
    answerField.secureTextEntry=YES;
    answerField.keyboardType = UIKeyboardTypeDefault;
    answerField.placeholder = @"current password";
    
    [alert show];
}

- (IBAction)dismissKeyboard:(id)sender {
    [nameField resignFirstResponder];
    [emailField resignFirstResponder];
    [orgField resignFirstResponder];
    [userNameField resignFirstResponder];
}

//keyboard handlers from http://astralbodies.net/blog/2012/02/01/resizing-a-uitextview-automatically-with-the-keyboard/
- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}
- (void)keyboardWillShow:(NSNotification*)notification {
    
    
    //determine who is first responder
    for (UIView *view in self.view.subviews)
    {
        if (view.isFirstResponder)
        {
            firstResponder = view;
            [self moveTextViewForKeyboard:notification up:YES];
            break;
        }
    }
}

- (void)keyboardWillHide:(NSNotification*)notification {
    [self moveTextViewForKeyboard:notification up:NO];

}
- (void)moveTextViewForKeyboard:(NSNotification*)notification up:(BOOL)up {
    NSDictionary *userInfo = [notification userInfo];
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect keyboardRect;
    
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    animationDuration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    keyboardRect = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardRect = [self.view convertRect:keyboardRect fromView:nil];
    
    CGFloat desiredRectOrigin = 200;
    
    [UIView beginAnimations:@"ResizeForKeyboard" context:nil];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];
    
    if (up == YES) {
        CGRect newTextViewFrame = self.view.frame;
        
        if (firstResponder.frame.origin.y+firstResponder.frame.size.height>desiredRectOrigin){//something that says whether the textfield is below the keyboard.
            newTextViewFrame.origin.y = -((keyboardRect.origin.y-desiredRectOrigin)+(firstResponder.frame.origin.y - keyboardRect.origin.y));//keyboard.origin.y-desiredlocation.origin.y+(oldvieworigin.y-keyboardorigin.y)
            [self.view setFrame:newTextViewFrame];
        }
    } else {
        
        // Keyboard is going away (down) - restore original frame
        [self.view setFrame:originalTextViewFrame];
    }
    
    [UIView commitAnimations];
    
}

- (IBAction)saveProfile:(id)sender {
    
    //put up an alert view.
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:@"Password"
                          message:@"For you security, updating your profile requires you to re-enter your password."
                          delegate:self
                          cancelButtonTitle: nil
                          otherButtonTitles:@"Continue", @"Cancel",nil ];
    
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    alert.tag=55;
    answerField = [alert textFieldAtIndex:0];
    answerField.secureTextEntry=YES;
    answerField.keyboardType = UIKeyboardTypeDefault;
    answerField.placeholder = @"password";
    
    [alert show];
}

- (IBAction)uploadPhoto:(id)sender {
    UIImagePickerController * picker = [[UIImagePickerController alloc] init];
    
    // Don't forget to add UIImagePickerControllerDelegate in your .h
    picker.delegate = self;
    
    if((UIButton *) sender == uploadButton) {
        picker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    }
    
    [self presentViewController:picker animated:YES completion:nil];
    
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    //put the photo in the image.
    UIImage * newImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    imageProfile.image = newImage;
    [self.view reloadInputViews];
    //close the pickerview
    changedImage = YES;
    [picker dismissViewControllerAnimated:YES completion:nil];
}
-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    //close the pickerview
    [picker dismissViewControllerAnimated:YES completion:nil];

}
-(UIImage *) resizeProfileImage{
    CGFloat realHeight = imageProfile.image.size.height;
    CGFloat realWidth = imageProfile.image.size.width;
    CGFloat newWidth = 320;
    CGFloat newHeight = (320 * realHeight)/realWidth;
    
    CGSize newSize=CGSizeMake(newWidth, newHeight);
    UIGraphicsBeginImageContext( newSize );
    [imageProfile.image drawInRect:CGRectMake(0,0,newWidth,newHeight)];
    
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    //save profile alert view
    if (alertView.tag==55){
        if (buttonIndex==0){
            //check the password, and if it works, save it.
            if ([PFUser logInWithUsername:[PFUser currentUser].username password:answerField.text]){
                
                //do the saving
                [PFUser currentUser].email = emailField.text;
                [[PFUser currentUser] setObject:nameField.text forKey:@"realName"];
                [[PFUser currentUser] setObject:orgField.text forKey:@"realOrg"];
                [[PFUser currentUser] setUsername:userNameField.text];
                
                if (changedImage){
                    UIImage * resizedImage = [self resizeProfileImage];
                    NSData * imageData = UIImagePNGRepresentation(resizedImage);
                    PFFile *userImageFile = [PFFile fileWithName:[NSString stringWithFormat:@"img_%@.png",[PFUser currentUser].objectId] data:imageData];
                    [[PFUser currentUser] setObject:userImageFile forKey:@"imageFile"];
                }
                
                [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if(error){
                        UIAlertView *alert = [[UIAlertView alloc]
                                              initWithTitle:@"Error"
                                              message:[error userInfo][@"error"]
                                              delegate:self
                                              cancelButtonTitle: nil
                                              otherButtonTitles:@"OK",nil ];
                        
                        alert.alertViewStyle = UIAlertViewStyleDefault;
                        alert.tag=59;
                        [alert show];
                    }
                    else{
                        UIAlertView *alert = [[UIAlertView alloc]
                                              initWithTitle:@"Success"
                                              message:@"Your profile has been saved."
                                              delegate:nil
                                              cancelButtonTitle: @"OK"
                                              otherButtonTitles: nil ];
                        
                        alert.alertViewStyle = UIAlertViewStyleDefault;
                        alert.tag=58;
                        [alert show];
                    }

                        
                }];
                
                [firstResponder resignFirstResponder];
                
                
            }
            //password was wrong, try again.
            else {
                UIAlertView *alert = [[UIAlertView alloc]
                                      initWithTitle:@"Try again"
                                      message:@"That was wrong."
                                      delegate:self
                                      cancelButtonTitle: nil
                                      otherButtonTitles:@"Continue", @"Cancel",nil ];
                
                alert.alertViewStyle = UIAlertViewStylePlainTextInput;
                alert.tag=55;
                answerField = [alert textFieldAtIndex:0];
                answerField.secureTextEntry=YES;
                answerField.keyboardType = UIKeyboardTypeDefault;
                answerField.placeholder = @"your password";
                
                [alert show];
                
            }
        }
        if (buttonIndex ==1){
            //dismiss alert.
        }
    }
    
    //for the change password alert view... old password
    if (alertView.tag == 56){
        if (buttonIndex==0){
            //check the password and if it's right, ask for new password
            if ([PFUser logInWithUsername:[PFUser currentUser].username password:answerField.text]){
                //put up an alert view.
                UIAlertView *alert = [[UIAlertView alloc]
                                      initWithTitle:@"New Password Needed"
                                      message:@"Please enter your new password."
                                      delegate:self
                                      cancelButtonTitle: nil
                                      otherButtonTitles:@"Continue", @"Cancel",nil ];
                
                alert.alertViewStyle = UIAlertViewStylePlainTextInput;
                alert.tag=57;
                answerField = [alert textFieldAtIndex:0];
                answerField.secureTextEntry=NO;
                answerField.keyboardType = UIKeyboardTypeDefault;
                answerField.placeholder = @"new password";
                
                [alert show];
                
            }
            //else they were wrong and they should try again.
            else {
                UIAlertView *alert = [[UIAlertView alloc]
                                      initWithTitle:@"Try again"
                                      message:@"That was wrong."
                                      delegate:self
                                      cancelButtonTitle: nil
                                      otherButtonTitles:@"Continue", @"Cancel",nil ];
                
                alert.alertViewStyle = UIAlertViewStylePlainTextInput;
                alert.tag=56;
                answerField = [alert textFieldAtIndex:0];
                answerField.secureTextEntry=YES;
                answerField.keyboardType = UIKeyboardTypeDefault;
                answerField.placeholder = @"current password";
                
                [alert show];

            }
            
        }
        if (buttonIndex==1){
            //dismiss the alert.
        }
    }
    
    //for the change password alert view... new password
    if (alertView.tag == 57){
        if (buttonIndex==0){
            //change the password
            [PFUser currentUser].password=answerField.text;
            [[PFUser currentUser] saveInBackground];
        }
        if (buttonIndex==1){
            //cancel
        }
    }
}

- (IBAction)editTeamsButton:(id)sender {
    TeamManagerViewController * tmvc = [self.storyboard instantiateViewControllerWithIdentifier:@"TeamManagerID"];
    [self.navigationController pushViewController:tmvc animated:YES];
}
@end
