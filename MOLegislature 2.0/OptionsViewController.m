//
//  OptionsViewController.m
//  MOLegislature 3.0
//
//  Created by Paul Rolfe on 3/23/13.
//  Copyright (c) 2013 Paul Rolfe. All rights reserved.
//

#import "OptionsViewController.h"
#import "StateIAPHelper.h"
#import "MFSideMenu.h"



@interface OptionsViewController (){
    NSArray *_products;
}

@end

@implementation OptionsViewController
@synthesize loadedStateLabel,logOutText,currentUserLabel;

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
    
    //for the first time they go to options after getting the new version.
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"v1.6FirstTime"] && [PFUser currentUser]){
        
        if(![PFAnonymousUtils isLinkedWithUser:[PFUser currentUser]]){//if they are not anonymous, do the segue
            [self performSegueWithIdentifier:@"EditProfileSegue" sender:self];
        }
    }
    if (![[PFUser currentUser] isAuthenticated] || [PFAnonymousUtils isLinkedWithUser:[PFUser currentUser]]){
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"firstTime"]){
            UIAlertView * notRealUser = [[UIAlertView alloc] initWithTitle:@"Consider logging in?" message:@"You are currently logged in anonymously or not at all. To use many of the features of this app, you need to create a free CapitolBuddy account." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [notRealUser show];
            [self.editProfileButtonView setUserInteractionEnabled:NO];
        }
    }

}

-(void) viewWillAppear:(BOOL)animated{
    [loadedStateLabel setText:[[NSUserDefaults standardUserDefaults] objectForKey:@"state"]];
    
    if ([PFUser currentUser].isAuthenticated){
        [logOutText setTitle:@"Log out" forState:UIControlStateNormal];
        currentUserLabel.text = [PFUser currentUser].username;
    }
    if (![PFUser currentUser].isAuthenticated){
        [logOutText setTitle:@"Log in" forState:UIControlStateNormal];
        currentUserLabel.text = @"n/a";
        //currentUserLabel.textColor = [UIColor grayColor];
    }
    if ([PFAnonymousUtils isLinkedWithUser:[PFUser currentUser]]) {
        [logOutText setTitle:@"Log in" forState:UIControlStateNormal];
        //currentUserLabel.textColor = nil;
        currentUserLabel.text = @"Anonymous";
    }
}
-(void)viewDidAppear:(BOOL)animated{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        if (UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation])){
            self.navigationItem.leftBarButtonItem=nil;
        }
    }
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)logOutButton:(id)sender {
    
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    
    if ([logOutText.titleLabel.text isEqualToString: @"Log out"]){
        [PFUser logOut];
        UIAlertView *logOut=[[UIAlertView alloc] initWithTitle:@"Logged Out" message:@"You are no longer logged in.\n\n (This means your purchases will not be backed up)" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [logOut show];
        [self.editProfileButtonView setUserInteractionEnabled:NO];
        
        DataLoader *toGetStrings = [[DataLoader alloc] init];
        NSString *filePath = [toGetStrings.GetDocumentDirectory stringByAppendingPathComponent:@"IAPstrings"];
        NSString * stateString = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
        NSArray *stateObjects = [stateString componentsSeparatedByString:@"\n"];
        for (NSString * productID in stateObjects){
            
            [defaults setObject:nil forKey:productID];
        }
                
        [defaults setObject:[NSDate date] forKey:@"RedOstrich.CapitolBuddy.Universal.RI"];
        [defaults setObject:@"RI" forKey:@"state"];
        [loadedStateLabel setText:[defaults objectForKey:@"state"]];
    }

    else {
    PFLogInViewController *logInViewController = [[PFLogInViewController alloc] init];
    [logInViewController.logInView setLogo:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"CB_text.png"]]];
    [logInViewController.logInView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"CB_background.png"]]];
    logInViewController.logInView.usernameField.backgroundColor=[UIColor colorWithWhite:0.5 alpha:0.4];
    logInViewController.logInView.passwordField.backgroundColor=[UIColor colorWithWhite:0.5 alpha:0.4];
    logInViewController.logInView.signUpLabel.text=@"Sign up to back up your notes and purchases.";
    logInViewController.logInView.signUpLabel.textColor=[UIColor colorWithWhite:1 alpha:1];
    [logInViewController.logInView.dismissButton setFrame: CGRectMake(10.0f, 10.0f,60.0f, 60.0f)];
    
    PFSignUpViewController *signUpViewController = [[PFSignUpViewController alloc] init];
    [signUpViewController.signUpView setLogo:[[UIImageView alloc]initWithImage:[UIImage imageNamed:@"CB_text.png"]]];
    [signUpViewController.signUpView.dismissButton setFrame:CGRectMake(10.0f, 10.0f, 60.0f, 60.0f)];
    [signUpViewController.signUpView setBackgroundColor:[UIColor colorWithWhite:.8 alpha:1]];
    signUpViewController.signUpView.usernameField.backgroundColor=[UIColor colorWithWhite:0.5 alpha:0.4];
    signUpViewController.signUpView.passwordField.backgroundColor=[UIColor colorWithWhite:0.5 alpha:0.4];
    signUpViewController.signUpView.emailField.backgroundColor=[UIColor colorWithWhite:0.5 alpha:0.4];
    
    [signUpViewController setDelegate:self]; // Set ourselves as the delegate
    
    // Assign our sign up controller to be displayed from the login controller
    [logInViewController setSignUpController:signUpViewController];
    
    [logInViewController setDelegate:self];
    [self presentViewController:logInViewController animated:YES completion:NULL];
    }
    
    [self reloadInputViews];
    [logOutText setTitle:@"Log in" forState:UIControlStateNormal];
    currentUserLabel.text = @"n/a";

}


- (IBAction)showLeftMenuPressed:(id)sender {
    [self.menuContainerViewController toggleLeftSideMenuCompletion:nil];

}
// -------------------------------------------------------------------------------
//	setNavigationPaneBarButtonItem:
//  Custom implementation for the navigationPaneBarButtonItem setter.
//  In addition to updating the _navigationPaneBarButtonItem ivar, it
//  reconfigures the toolbar to either show or hide the
//  navigationPaneBarButtonItem.
// -------------------------------------------------------------------------------
- (void)setNavigationPaneBarButtonItem:(UIBarButtonItem *)navigationPaneBarButtonItem
{
    if (navigationPaneBarButtonItem != _navigationPaneBarButtonItem) {
        if (navigationPaneBarButtonItem)
            [self.navigationItem setLeftBarButtonItem: navigationPaneBarButtonItem
                                            animated:NO];
        else
            [self.navigationItem setLeftBarButtonItem:nil
                                            animated:NO];
    }
    
    _navigationPaneBarButtonItem = navigationPaneBarButtonItem;
    
    
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}




#pragma mark - PFLogInViewControllerDelegate

// Sent to the delegate to determine whether the log in request should be submitted to the server.
- (BOOL)logInViewController:(PFLogInViewController *)logInController shouldBeginLogInWithUsername:(NSString *)username password:(NSString *)password {
    // Check if both fields are completed
    if (username && password && username.length && password.length) {
        return YES; // Begin login process
    }
    
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Missing Information", nil) message:NSLocalizedString(@"Make sure you fill out all of the information!", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
    return NO; // Interrupt login process
}

// Sent to the delegate when a PFUser is logged in.
- (void)logInViewController:(PFLogInViewController *)logInController didLogInUser:(PFUser *)user {
    [self dismissViewControllerAnimated:YES completion:NULL];
    logOutText.titleLabel.text = @"Log out";
    [self.editProfileButtonView setUserInteractionEnabled:YES];
    
    //get the productIds to restore transactions.
    DataLoader *toGetStrings = [[DataLoader alloc] init];
    NSString *filePath = [toGetStrings.GetDocumentDirectory stringByAppendingPathComponent:@"IAPstrings"];
    NSString * stateString = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    NSArray *stateObjects = [stateString componentsSeparatedByString:@"\n"];
    
    //Restore everything.
    [[StateIAPHelper sharedInstance] restoreCompletedTransactionsForProducts:stateObjects];
    
}

// Sent to the delegate when the log in attempt fails.
- (void)logInViewController:(PFLogInViewController *)logInController didFailToLogInWithError:(NSError *)error {
    NSLog(@"Failed to log in...");
}

// Sent to the delegate when the log in screen is dismissed.
- (void)logInViewControllerDidCancelLogIn:(PFLogInViewController *)logInController {
    [self.navigationController popViewControllerAnimated:YES];
}
#pragma mark - PFSignUpViewControllerDelegate

// Sent to the delegate to determine whether the sign up request should be submitted to the server.
- (BOOL)signUpViewController:(PFSignUpViewController *)signUpController shouldBeginSignUp:(NSDictionary *)info {
    BOOL informationComplete = YES;
    
    // loop through all of the submitted data
    for (id key in info) {
        NSString *field = [info objectForKey:key];
        if (!field || !field.length) { // check completion
            informationComplete = NO;
            break;
        }
    }
    
    // Display an alert if a field wasn't completed
    if (!informationComplete) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Missing Information", nil) message:NSLocalizedString(@"Make sure you fill out all of the information!", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
    }
    
    return informationComplete;
}

// Sent to the delegate when a PFUser is signed up.
- (void)signUpViewController:(PFSignUpViewController *)signUpController didSignUpUser:(PFUser *)user {
    [self dismissViewControllerAnimated:YES completion:NULL];
    [self.editProfileButtonView setUserInteractionEnabled:YES];
}

// Sent to the delegate when the sign up attempt fails.
- (void)signUpViewController:(PFSignUpViewController *)signUpController didFailToSignUpWithError:(NSError *)error {
    NSLog(@"Failed to sign up...");
}

// Sent to the delegate when the sign up screen is dismissed.
- (void)signUpViewControllerDidCancelSignUp:(PFSignUpViewController *)signUpController {
    NSLog(@"User dismissed the signUpViewController");
}
@end
