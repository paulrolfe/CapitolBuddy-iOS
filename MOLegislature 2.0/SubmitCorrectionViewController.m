//
//  SubmitCorrectionViewController.m
//  CapitolBuddy
//
//  Created by Paul Rolfe on 4/24/14.
//  Copyright (c) 2014 Paul Rolfe. All rights reserved.
//

#import "SubmitCorrectionViewController.h"

@interface SubmitCorrectionViewController ()

@end

@implementation SubmitCorrectionViewController
@synthesize commentField, fieldPicker,currentLeg;

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
    // Do any additional setup after loading the view.
    fieldPicker.delegate=self;
    fieldPicker.dataSource=self;
    commentField.delegate=self;
    
    fieldArray = [[NSArray alloc] initWithObjects:@"Name",@"District",@"Chamber",@"Party",@"Phone",@"Email",@"Office",@"Website",@"Staff",@"Hometown", @"Committees",@"Bio",@"Other", nil];
    
    originalTextViewFrame = self.view.frame;
    
    // Register notifications for when the keyboard appears
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)keyboardWillShow:(NSNotification*)notification {
    [fieldPicker setUserInteractionEnabled:NO];
    
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
    [fieldPicker setUserInteractionEnabled:YES];
    [self moveTextViewForKeyboard:notification up:NO];
}
- (void)moveTextViewForKeyboard:(NSNotification*)notification up:(BOOL)up {
    if ([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPad){
    NSDictionary *userInfo = [notification userInfo];
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect keyboardRect;
    
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    animationDuration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    keyboardRect = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardRect = [self.view convertRect:keyboardRect fromView:nil];
    
    CGFloat desiredRectOrigin = 100;
    
    [UIView beginAnimations:@"ResizeForKeyboard" context:nil];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];
    
    if (up == YES) {
        CGRect newTextViewFrame = self.view.frame;
        newTextViewFrame.origin.y = -((keyboardRect.origin.y-desiredRectOrigin)+(firstResponder.frame.origin.y - keyboardRect.origin.y));
        [self.view setFrame:newTextViewFrame];
    } else {
        
        // Keyboard is going away (down) - restore original frame
        [self.view setFrame:originalTextViewFrame];
    }
    
    [UIView commitAnimations];
    }
}

-(NSInteger) numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}
-(NSInteger) pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    return fieldArray.count;
}
-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    return [fieldArray objectAtIndex:row];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
//creates an id from a leg object formula is [State][s/h][district] as in MOH051;
- (NSString *) createLegIDforLeg:(Legs *)legislator{
    NSString *state = [[NSUserDefaults standardUserDefaults] objectForKey:@"state"];
    
    int digits = [legislator.district intValue];
    NSString *threeDigits = [NSString stringWithFormat:@"%03d",digits];
    NSString * legID = [NSString stringWithFormat:@"%@%@%@",state,legislator.hstype,threeDigits];
    
    return legID;
}

- (IBAction)backButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)keyboardCancelButton:(id)sender {
    [commentField resignFirstResponder];
}
- (IBAction)submitButton:(id)sender {
    //some cloud function.
    [PFCloud callFunctionInBackground:@"submitCorrection"
                       withParameters:@{@"userId" : [PFUser currentUser].objectId,
                                        @"legId" : [self createLegIDforLeg:currentLeg],
                                        @"field" : [fieldArray objectAtIndex:[fieldPicker selectedRowInComponent:0]],
                                        @"comment" : commentField.text}
                                block:^(NSString *result, NSError *error) {
                                    if (!error) {
                                        NSLog(@"Email sent!");
                                        UIAlertView * emailSent = [[UIAlertView alloc] initWithTitle:@"Thanks" message:@"We'll get right on it! We may follow up with you if necessary." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                                        [emailSent show];
                                    }
                                    else{
                                        UIAlertView * noEmailSent = [[UIAlertView alloc] initWithTitle:@"Error" message:[error userInfo][@"error"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                                        [noEmailSent show];
                                    }
                                }];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
