//
//  ChangeStateViewController.m
//  CapitolBuddy
//
//  Created by Paul Rolfe on 9/11/13.
//  Copyright (c) 2013 Paul Rolfe. All rights reserved.
//

#import "ChangeStateViewController.h"

// 1
#import "StateIAPHelper.h"
#import "DataLoader.h"
#import <StoreKit/StoreKit.h>
#import "StatesClass.h"


// 2
@interface ChangeStateViewController () {
    NSMutableArray *_products;
    NSMutableArray * _productsNPO;
    NSNumberFormatter * _priceFormatter;
    NSMutableArray *purchasedProducts;
}
@end

@implementation ChangeStateViewController

// 3
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Change State";
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(reload) forControlEvents:UIControlEventValueChanged];
    [self reload];
    [self.refreshControl beginRefreshing];
    
    _priceFormatter = [[NSNumberFormatter alloc] init];
    [_priceFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [_priceFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    
    //display the restore button.
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Support" style:UIBarButtonItemStyleBordered target:self action:@selector(supportTapped:)];
}

// 4
- (void)reload {
    
    //do the restoring on load anyways.
    DataLoader *toGetStrings = [[DataLoader alloc] init];
    NSString *filePath = [toGetStrings.GetDocumentDirectory stringByAppendingPathComponent:@"IAPstrings"];
    NSString * stateString = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    NSArray *stateObjects = [stateString componentsSeparatedByString:@"\n"];
    [[StateIAPHelper sharedInstance] restoreCompletedTransactionsForProducts:stateObjects];
    
    [[StateIAPHelper sharedInstance] requestProductsWithCompletionHandler:^(BOOL success, NSArray *products) {
        if (success) {
            _products = [[NSMutableArray alloc]init];
            _productsNPO = [[NSMutableArray alloc] init];
            
            for (SKProduct * product in products){
                NSString * substr = [product.productIdentifier substringFromIndex:product.productIdentifier.length-6];
                substr = [substr substringToIndex:3];
                if ([substr isEqualToString:@"NPO"]){
                    NSLog(@"Found NPO product: %@",product.productIdentifier);
                    [_productsNPO addObject:product];
                }
                else{
                    [_products addObject:product];
                    NSLog(@"Found product: %@",product.productIdentifier);

                }
            }
            
        }
        purchasedProducts = nil;
        purchasedProducts = [[NSMutableArray alloc]init];
        
        DataLoader *toGetStrings = [[DataLoader alloc] init];
        NSString *filePath = [toGetStrings.GetDocumentDirectory stringByAppendingPathComponent:@"IAPstrings"];
        NSString * stateString = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
        NSArray *stateObjects = [stateString componentsSeparatedByString:@"\n"];
        for (NSString * productID in stateObjects){
            
            StatesClass * stateObj =[[StatesClass alloc]initPurchasedProductsWithIdentifier:productID];
            if (stateObj.productIdentifier!=nil){
                [purchasedProducts addObject:stateObj];
            }
        }
        [self.tableView reloadData];
        [self.refreshControl endRefreshing];
    }];
    
}

- (IBAction)backButtonForiPad:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (section == 0) {
        return @"Purchased";
    }
    if (section == 1) {
        return @"The Store";
    }
    else {
        return @"Error";
    }
}


// 5
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section ==0){
        return purchasedProducts.count;
    }
    if (section == 1){
        if (npoON)
            return _productsNPO.count;
        else
            return _products.count;
    }
    else {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"StateCell" forIndexPath:indexPath];
    
    if (indexPath.section ==0){
        StatesClass * purchasedState = [purchasedProducts objectAtIndex:indexPath.row];
        
        cell.textLabel.text = purchasedState.displayName;
       
        
        NSString *chosenState =[[NSUserDefaults standardUserDefaults] objectForKey:@"state"];
        
        if ([purchasedState.stateCode isEqualToString:@"RI"]){
            cell.detailTextLabel.text = @"Always Available";
        }
        else{
             cell.detailTextLabel.text = purchasedState.expirationDateString;
        }

        
        if([chosenState isEqualToString:purchasedState.stateCode]){
            cell.accessoryView = nil;
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.accessoryView = nil;
        }
    }
    
    if (indexPath.section ==1){
        SKProduct * product;
        if (npoON)
            product=(SKProduct *) _productsNPO[indexPath.row];
        if (!npoON)
            product= (SKProduct *) _products[indexPath.row];

        
        //set the label on all cells
        cell.textLabel.text = product.localizedTitle;
        
        [_priceFormatter setLocale:product.priceLocale];

        if ([[StateIAPHelper sharedInstance] daysRemainingOnSubscriptionForProduct:product.productIdentifier] > 0) {
            
            cell.accessoryView = nil;
            
                    //Get strings to determine the current State
            NSString *chosenState =[[NSUserDefaults standardUserDefaults] objectForKey:@"state"];
            NSString *mystr = product.productIdentifier;
            NSString *lastLetters=[mystr substringFromIndex:[mystr length] -2];
            cell.detailTextLabel.text = [[StateIAPHelper sharedInstance] getExpirationDateStringForProduct:product.productIdentifier];
            
            if([chosenState isEqualToString:lastLetters]){
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            else{
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            
        }
        //when it's available for purchase
        else {
            //Is it in coupon code mode?
            if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"promoCodeIsActive"] isEqualToString:@"YES"]){
                //Make the same button but select goes elsewhere.
                UIButton *buyButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
                buyButton.frame = CGRectMake(0, 0, 85, 37);
                [buyButton setTitle:@"Select" forState:UIControlStateNormal];
                [buyButton addTarget:self action:@selector(promoPurchase:) forControlEvents:UIControlEventTouchUpInside];
                cell.accessoryType = UITableViewCellAccessoryNone;
                buyButton.tag = indexPath.row;
                cell.accessoryView = buyButton;
                
                cell.detailTextLabel.text = @"Free for 1 year";
            }
            else{
                UIButton *buyButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
                buyButton.frame = CGRectMake(0, 0, 85, 37);
                [buyButton setTitle:@"Subscribe" forState:UIControlStateNormal];
                [buyButton addTarget:self action:@selector(buyButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
                cell.accessoryType = UITableViewCellAccessoryNone;
                buyButton.tag = indexPath.row;
                cell.accessoryView = buyButton;
                
                NSString *price=[_priceFormatter stringFromNumber:product.price];
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ / year",price];
            }
        }
    }
        return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section ==0){
        StatesClass * purchasedState = [purchasedProducts objectAtIndex:indexPath.row];
        
        [[NSUserDefaults standardUserDefaults] setObject:purchasedState.stateCode forKey:@"state"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self reload];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            
            //copy the photos
            DataLoader *dbCrud=[[DataLoader alloc] init];
            [dbCrud CopyDbToDocumentsFolder];
            [dbCrud DownloadNewPhotos];
            [(AppDelegate *)[UIApplication sharedApplication].delegate findCapitolBuilding];
        });
        
        NSString * strMessage=[NSString stringWithFormat:@"%@ has loaded, see the legislators by navigating to the side menu.",purchasedState.displayName];
        
        UIAlertView *stateMessage=[[UIAlertView alloc] initWithTitle:@"You got it." message:strMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [stateMessage show];
        
        //if in a split view controller, reload the table view with the new state.
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
            UITabBarController * tbc=[self.splitViewController.viewControllers objectAtIndex:0];
            
            for (UITableViewController * tvc in tbc.viewControllers){
                [tvc loadView];
            }
        }
    }
    if (indexPath.section == 1){
        SKProduct * product;
        if (npoON)
            product = (SKProduct *) _productsNPO[indexPath.row];
        if (!npoON)
            product = (SKProduct *) _products[indexPath.row];
        
        
        if ([[StateIAPHelper sharedInstance] daysRemainingOnSubscriptionForProduct:product.productIdentifier] > 0){
    
            NSString *mystr = product.productIdentifier;
            NSString *chosenState=[mystr substringFromIndex:[mystr length] -2];
        
            [[NSUserDefaults standardUserDefaults] setObject:chosenState forKey:@"state"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self reload];
        
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            
                //copy the photos
                DataLoader *dbCrud=[[DataLoader alloc] init];
                [dbCrud CopyDbToDocumentsFolder];
                [dbCrud DownloadNewPhotos];
                [(AppDelegate *)[UIApplication sharedApplication].delegate findCapitolBuilding];

            });
        
            NSString * strMessage=[NSString stringWithFormat:@"%@ has loaded, see the legislators by navigating to the side menu.",product.localizedTitle];
        
            UIAlertView *stateMessage=[[UIAlertView alloc] initWithTitle:@"You got it." message:strMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [stateMessage show];

        }
        else{
            UIAlertView *stateMessage=[[UIAlertView alloc] initWithTitle:@"Sorry." message:@"You need to subscribe to this state before you can select it." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [stateMessage show];
            [tableView deselectRowAtIndexPath:indexPath animated:YES];

        }
    }
}

- (IBAction)couponCodeButton:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:@"Have a promo code?"
                          message:@"Please enter the code below.\n(it's case sensitive)."
                          delegate:self
                          cancelButtonTitle:@"Cancel"
                          otherButtonTitles:@"Redeem",nil];
    
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    alert.tag=55;
    answerField = [alert textFieldAtIndex:0];
    answerField.secureTextEntry=NO;
    answerField.keyboardType = UIKeyboardTypeDefault;
    answerField.placeholder = @"promo code";
    
    [alert show];
    
}

- (void)buyButtonTapped:(id)sender {
    
    UIButton *buyButton = (UIButton *)sender;
    SKProduct * product;
    if (npoON)
        product = (SKProduct *) _productsNPO[buyButton.tag];
    if (!npoON)
        product = (SKProduct *) _products[buyButton.tag];
    
    if ([PFUser currentUser].isAuthenticated){
        
        if(![PFAnonymousUtils isLinkedWithUser:[PFUser currentUser]]){
            
            NSLog(@"Buying %@...", product.productIdentifier);

            [PFPurchase buyProduct:product.productIdentifier block:^(NSError *error) {
                if (!error) {
                    UIAlertView *result=[[UIAlertView alloc] initWithTitle:@"Product purchased!" message:[NSString stringWithFormat:@"Good luck with those legislators in %@",product.localizedTitle] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [result show];
                    [[PFUser currentUser] setObject:[NSNumber numberWithBool:YES] forKey:@"isPayer"];
                    [[PFUser currentUser] saveInBackground];
                    npoON=NO;
                    
                }
                if (error){
                    UIAlertView *result=[[UIAlertView alloc] initWithTitle:@"Product not purchased" message:@"There was an error making the purchase, please try again later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [result show];
                }
            }];
        }
    }
    
    if (![PFUser currentUser].isAuthenticated) {
        UIAlertView *result=[[UIAlertView alloc] initWithTitle:@"Please Log In First" message:@"You are not currently logged in to CapitolBuddy. Please log in to CapitolBuddy with a username and password, so your purchases can be backed up." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [result show];
        
        [self showLogInController];
    }

    if([PFAnonymousUtils isLinkedWithUser:[PFUser currentUser]]) {
        UIAlertView *result=[[UIAlertView alloc] initWithTitle:@"Please Log In First" message:@"You are currently logged in as an anonymous user. Please log in to CapitolBuddy with a username and password, so your purchases can be backed up." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [result show];
        
        [self showLogInController];
       
    }
    
}
- (void) promoPurchase:(id)sender {
    //after the promopurchase, change the buttons back to select
    UIButton *buyButton = (UIButton *)sender;
    SKProduct *product = _products[buyButton.tag];
    
    if ([PFUser currentUser].isAuthenticated){
        
        if(![PFAnonymousUtils isLinkedWithUser:[PFUser currentUser]]){
            
            NSLog(@"Buying %@...", product.productIdentifier);
            
            [[StateIAPHelper sharedInstance] provideContentForProductIdentifier:product.productIdentifier];
            [[NSUserDefaults standardUserDefaults] setObject:@"NO" forKey:@"promoCodeIsActive"];
            self.navigationItem.prompt=nil;
            
            UIAlertView *result=[[UIAlertView alloc] initWithTitle:@"Product purchased!" message:[NSString stringWithFormat:@"Good luck with those legislators in %@",product.localizedTitle] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [result show];
            
            //note that they are not a paying user in Parse.
            [[PFUser currentUser] setObject:[NSNumber numberWithBool:NO] forKey:@"isPayer"];
            [[PFUser currentUser] saveInBackground];
            
            [self.tableView reloadData];
        }
    }
    if (![PFUser currentUser].isAuthenticated) {
        UIAlertView *result=[[UIAlertView alloc] initWithTitle:@"Please Log In First" message:@"You are not currently logged in to CapitolBuddy. Please log in to CapitolBuddy with a username and password, so your purchases can be backed up." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [result show];
        
        [self showLogInController];

    }
    if([PFAnonymousUtils isLinkedWithUser:[PFUser currentUser]]) {
        UIAlertView *result=[[UIAlertView alloc] initWithTitle:@"Please Log In First" message:@"You are currently logged in as an anonymous user. Please log in to CapitolBuddy with a username and password, so your purchases can be backed up." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [result show];
        
        [self showLogInController];

    }
    
}

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:IAPHelperProductPurchasedNotification object:nil];
}
- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSUserDefaults standardUserDefaults] setObject:@"NO" forKey:@"promoCodeIsActive"];
    self.navigationItem.prompt=nil;
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex==1){
        //Do a parse function to see if it's real. If they are signed in.
        if ([[PFUser currentUser] isAuthenticated])
            [PFCloud callFunctionInBackground:@"promoCodeCheck"
                           withParameters:@{@"code" : answerField.text,
                                            @"userId" : [PFUser currentUser].objectId}
                            block:^(NSString * response, NSError *error) {
                                if (!error){
                                    //When it returns success, change the button on every index to select promo purchase

                                    if ([response isEqualToString:@"npoGO"]){
                                        //download the new states...
                                        npoON=YES;
                                        self.navigationItem.prompt=@"Success, you've got the non-profit rate!";
                                        [self.tableView reloadData];
                                    }
                                    else if ([response isEqualToString:@"Free code"]){
                                        [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"promoCodeIsActive"];
                                        self.navigationItem.prompt=@"Success, select your state!";
                                    }
                                    [self.tableView reloadData];
                                }
                                if (error){
                                    UIAlertView * badCode = [[UIAlertView alloc] initWithTitle:@"Error" message:[error userInfo][@"error"] delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
                                    [badCode show];
                                }
                            }];
        else{
            UIAlertView * pleaseLogIn = [[UIAlertView alloc] initWithTitle:@"Please Log In" message:@"To use this feature you need to first log in as a CapitolBuddy user." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [pleaseLogIn show];
        }
    }
}

- (void)supportTapped:(id)sender {
    if ([MFMailComposeViewController canSendMail])
    {
        MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
        mailer.mailComposeDelegate = self;
        [mailer setSubject:[NSString stringWithFormat:@"Help request from %@",[PFUser currentUser].username]];
        
        NSArray *toRecipients = [NSArray arrayWithObjects:@"support@capitolbuddy.com",nil];
        [mailer setToRecipients:toRecipients];
        
        NSString *emailBody = @"I need help with something... (please describe your problem here)";
        [mailer setMessageBody:emailBody isHTML:NO];
        [self presentViewController:mailer animated:YES completion:nil];
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failure" message:@"Your device doesn't support the composer sheet" delegate:nil cancelButtonTitle:@"OK"otherButtonTitles:nil];
        [alert show];
    }

}
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    NSString *myCase;
    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled: you cancelled the operation and no email message was queued.");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved: you saved the email message in the drafts folder.");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Mail send: the email message is queued in the outbox. It is ready to send.");
            myCase=@"Sent";
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail failed: the email message was not saved or queued, possibly due to an error.");
            break;
        default:
            NSLog(@"Mail not sent.");
            break;
    }
    
    // Remove the mail view
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - PFLogInViewControllerDelegate
-(void) showLogInController{
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
    
    DataLoader *toGetStrings = [[DataLoader alloc] init];
    NSString *filePath = [toGetStrings.GetDocumentDirectory stringByAppendingPathComponent:@"IAPstrings"];
    NSString * stateString = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    NSArray *stateObjects = [stateString componentsSeparatedByString:@"\n"];
   
    [[StateIAPHelper sharedInstance] restoreCompletedTransactionsForProducts:stateObjects];
    //[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"You're logged in", nil) message:NSLocalizedString(@"Now you can click 'Restore'", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
    
    [self reload];
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
