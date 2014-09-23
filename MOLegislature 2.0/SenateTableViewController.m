//
//  SenateTableViewController.m
//  MOLegislature 2.0
//
//  Created by Paul Rolfe on 2/26/13.
//  Copyright (c) 2013 Paul Rolfe. All rights reserved.
//

#import "SenateTableViewController.h"


@interface SenateTableViewController ()

@end

@implementation SenateTableViewController
@synthesize senators;
@synthesize fileMgr,homeDir;
/*UISwipeGestureRecognizer* gestureR;
UISwipeGestureRecognizer* gestureL;*/
Legs * selectedLegToSave;
UITextField* answerField;


-(NSString *)GetDocumentDirectory{
    fileMgr = [NSFileManager defaultManager];
    homeDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    
    return homeDir;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}
-(void)viewWillAppear:(BOOL)animated{
    
    senators = [[NSArray alloc] initWithArray:[DataLoader database].senators];
    
    NSString * state = [[NSUserDefaults standardUserDefaults] objectForKey:@"state"];
    self.navigationItem.title = [NSString stringWithFormat:@"%@ Senate",state];
    
    [self.tableView reloadData];
    
}
- (void)viewDidLoad
{
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshLegs) forControlEvents:UIControlEventValueChanged];

    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {

        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
        SideMenuViewController *content = [storyboard instantiateViewControllerWithIdentifier:@"SideMenu"];
        self.barButtonItemPopover = [[UIPopoverController alloc] initWithContentViewController:content];
        self.barButtonItemPopover.popoverContentSize = CGSizeMake(320., 550.);
        content.barButtonItemPopover = self.barButtonItemPopover;
        content.detailViewManager=(DetailViewManager*)self.splitViewController.delegate;
        self.barButtonItemPopover.delegate = self;
        
    }
    
    senators = [[NSArray alloc] initWithArray:[DataLoader database].senators];
    
    //Set the prompt if in link saving mode.
    if (![[[NSUserDefaults standardUserDefaults] objectForKey:@"viewForLinkSave"] isEqualToString:@"NO"]){
        self.navigationItem.prompt=@"Attach this link to notes by selecting a legislator.";
        self.navigationItem.leftBarButtonItem=nil;
        UIBarButtonItem * backToNews = [[UIBarButtonItem alloc]initWithTitle:@"Back to News" style:UIBarButtonItemStylePlain target:self action:@selector(showLeftMenuPressed:)];
        self.navigationItem.leftBarButtonItem=backToNews;

    }
    [super viewDidLoad];

    
}
-(void)refreshLegs{
    senators = [[NSArray alloc] initWithArray:[DataLoader database].senators];
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    NSString *currentProduct = [NSString stringWithFormat:@"RedOstrich.CapitolBuddy.Universal.%@",[[NSUserDefaults standardUserDefaults] objectForKey:@"state"]];
    if ([[StateIAPHelper sharedInstance] daysRemainingOnSubscriptionForProduct:currentProduct] == 0){
        senators=nil;
        [[NSUserDefaults standardUserDefaults]setObject:@"RI" forKey:@"state"];
        [[NSUserDefaults standardUserDefaults]synchronize];
    }
    
    if (![PFUser currentUser]) { // No user logged in
        // Create the log in view controller
        PFLogInViewController *logInViewController = [[PFLogInViewController alloc] init];
        [logInViewController.logInView setLogo:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"CB_text.png"]]];
        [logInViewController.logInView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"CB_background.png"]]];
        logInViewController.logInView.usernameField.backgroundColor=[UIColor colorWithWhite:0.5 alpha:0.4];
        logInViewController.logInView.passwordField.backgroundColor=[UIColor colorWithWhite:0.5 alpha:0.4];
        logInViewController.logInView.signUpLabel.text=@"Sign up to back up your notes and purchases.";
        logInViewController.logInView.signUpLabel.textColor=[UIColor colorWithWhite:1 alpha:1];
        logInViewController.logInView.signUpButton.backgroundColor=[UIColor clearColor];
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
   
}
-(void) firstTimeMessage{
    //if there's no file then show the first open message
    UIAlertView *firstLoad=[[UIAlertView alloc] initWithTitle:@"First Open" message:@"Thanks for trying CapitolBuddy.\n\n Rhode Island's legislators come free with the app. \n\n You can buy access to more states in the Options tab in the side menu." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [firstLoad show];
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"firstTime"];
    //indicates it is not their first log in.
}

- (void)didReceiveMemoryWarning{
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - TableData

- (void)filterContentForSearchText:(NSString*)searchText
{
    NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"(name contains[cd] %@) OR (district contains[cd] %@) OR (hometown contains[cd] %@) OR (leadership contains[cd] %@)",searchText, searchText, searchText, searchText];
    
    searchResults = [senators filteredArrayUsingPredicate:resultPredicate];
}

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller
shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString];
    
    return YES;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return [searchResults count];
    }
    if (senators.count==0){
        return 1;
    }
    else {
        return [senators count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    static NSString *CellIdentifier = @"SenateCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    //SearchResults View
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        Legs * current2 = [searchResults objectAtIndex:[indexPath row]];
        [[cell textLabel] setText:[current2 name]];
        cell.detailTextLabel.text=[NSString stringWithFormat:@"(%@) District %@ -- %@",current2.hstype, current2.district, current2.party];
        cell.detailTextLabel.backgroundColor=[UIColor clearColor];
        cell.textLabel.backgroundColor=[UIColor clearColor];

        cell.detailTextLabel.textColor=[UIColor colorWithWhite:0.0 alpha:.8];
        
        //retrieve image from local directory.
        NSString *pngName = current2.imageFile;
        NSString *pngPath = [self.GetDocumentDirectory stringByAppendingPathComponent:pngName];
        UIImage *image = [UIImage imageWithContentsOfFile: pngPath];
        [[cell imageView] setImage:image];
        
        cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
        UIView * myBG = [[UIView alloc] initWithFrame:CGRectZero];
        if ([current2.party isEqualToString:@"D"]) {
            myBG.backgroundColor = [UIColor colorWithRed:0.1 green:0.3 blue:0.5 alpha:0.6];
        }
        if ([current2.party isEqualToString:@"R"]) {
            myBG.backgroundColor = [UIColor colorWithRed:0.8 green:0.3 blue:0.1 alpha:0.6];
        }
        if ([current2.party isEqualToString:@"I"]){
            myBG.backgroundColor = [UIColor colorWithRed:0.3 green:0.1 blue:0.3 alpha:0.6];
        }
        if ([current2.party isEqualToString:@"NONE"]){
            myBG.backgroundColor = [UIColor whiteColor];
        }
        cell.backgroundView=myBG;
        
        [[cell.contentView viewWithTag:125] removeFromSuperview];
        if (![current2.leadership isEqualToString:@"NONE"]){
            CGRect imageRect = {182,26,130,17};
            UILabel * label = [[UILabel alloc] initWithFrame:imageRect];
            label.textAlignment = NSTextAlignmentCenter;
            label.backgroundColor=[UIColor colorWithWhite:.1 alpha:.5];
            label.textColor = [UIColor whiteColor];
            label.font=[UIFont systemFontOfSize:10];
            label.text = current2.leadership;
            label.tag=125;
            [cell.contentView addSubview:label];
        }


    }
    //Normal TableView
    else {
        //...with no data.
        if(senators.count==0){
            cell.textLabel.text=@"Error";
            cell.detailTextLabel.text=@"Please check network connectivity";
            cell.userInteractionEnabled=NO;
        }
        //...normal cell view set up
        else{
            cell.userInteractionEnabled=YES;
            
            Legs *info=[senators objectAtIndex:indexPath.row];
            cell.textLabel.text=info.name;
            cell.detailTextLabel.text=[NSString stringWithFormat:@"(%@) District %@ -- %@",info.hstype, info.district, info.party];
            cell.detailTextLabel.textColor=[UIColor colorWithWhite:0.0 alpha:.8];
        
            //Retrieve an image
            NSString *pngName = info.imageFile;
            NSString *pngPath = [self.GetDocumentDirectory stringByAppendingPathComponent:pngName];
            UIImage *image = [UIImage imageWithContentsOfFile: pngPath];
            //Add the image to the table cell
            [[cell imageView] setImage:image];
        
            //Set the cell tint based on d/r
            cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
            UIView * myBG = [[UIView alloc] initWithFrame:CGRectZero];
            
            //Set the cell tint based on d/r
            if ([info.party isEqualToString:@"D"]) {
                myBG.backgroundColor = [UIColor colorWithRed:0.1 green:0.3 blue:0.5 alpha:0.6];
            }
            if ([info.party isEqualToString:@"R"]) {
                myBG.backgroundColor = [UIColor colorWithRed:0.8 green:0.3 blue:0.1 alpha:0.6];
            }
            if ([info.party isEqualToString:@"I"]){
                myBG.backgroundColor = [UIColor colorWithRed:0.3 green:0.1 blue:0.3 alpha:0.6];
            }
            if ([info.party isEqualToString:@"NONE"]){
                myBG.backgroundColor = [UIColor whiteColor];
            }
            cell.backgroundView=myBG;
            
            //Add leadership label
            [[cell.contentView viewWithTag:124] removeFromSuperview];
            if (![info.leadership isEqualToString:@"NONE"]){
                CGRect imageRect = {182,26,130,17};
                UILabel * label = [[UILabel alloc] initWithFrame:imageRect];
                label.textAlignment = NSTextAlignmentCenter;
                label.backgroundColor=[UIColor colorWithWhite:.1 alpha:.5];
                label.textColor = [UIColor whiteColor];
                label.font=[UIFont systemFontOfSize:10];
                label.text = info.leadership;
                label.tag=124;
                [cell.contentView addSubview:label];
            }
        }
    }
    
    return cell;
}


#pragma mark - Navigation

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {

        // Get a reference to the DetailViewManager.
        // DetailViewManager is the delegate of our split view.
        DetailViewManager *detailViewManager = (DetailViewManager*)self.splitViewController.delegate;
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"PadStoryboard" bundle:[NSBundle mainBundle]];
        UINavigationController *newDetailNavViewController = [storyboard instantiateViewControllerWithIdentifier:@"InfoNavID"];
        InfoViewController *newDetailViewController = [newDetailNavViewController.viewControllers firstObject];
        
        if (tableView == self.searchDisplayController.searchResultsTableView) {
            Legs *c= [searchResults objectAtIndex:[indexPath row]];
            newDetailViewController.currentLeg=c;
            detailViewManager.detailNavigationViewController = newDetailNavViewController;


        }
        else{
            Legs *c= [senators objectAtIndex:[indexPath row]];
            [newDetailViewController setCurrentLeg:c];
            detailViewManager.detailNavigationViewController = newDetailNavViewController;

            
        }
        
        if (![[[NSUserDefaults standardUserDefaults] objectForKey:@"viewForLinkSave"] isEqualToString:@"NO"]){
            
            if (tableView == self.searchDisplayController.searchResultsTableView) {
                selectedLegToSave = [searchResults objectAtIndex:indexPath.row];
            }
            else{
                selectedLegToSave = [senators objectAtIndex:indexPath.row];
            }
            
            //Show a popup, asking them to save.
            UIAlertView *saveLinkAlert=[[UIAlertView alloc]
                                        initWithTitle:@"Save link here?"
                                        message:[NSString stringWithFormat:@"Enter a short description of this link for Sen. %@'s notes",selectedLegToSave.name]
                                        delegate:self cancelButtonTitle:@"Cancel"
                                        otherButtonTitles:@"Save",nil];
            saveLinkAlert.alertViewStyle=UIAlertViewStylePlainTextInput;
            answerField = [saveLinkAlert textFieldAtIndex:0];
            answerField.keyboardType = UIKeyboardTypeDefault;
            answerField.placeholder = @"link description";
            [saveLinkAlert show];
        }
        
    }
    else{
        if (![[[NSUserDefaults standardUserDefaults] objectForKey:@"viewForLinkSave"] isEqualToString:@"NO"]){
            
            if (tableView == self.searchDisplayController.searchResultsTableView) {
                selectedLegToSave = [searchResults objectAtIndex:indexPath.row];
            }
            else{
                selectedLegToSave = [senators objectAtIndex:indexPath.row];
            }
            
            //Show a popup, asking them to save.
            UIAlertView *saveLinkAlert=[[UIAlertView alloc]
                                        initWithTitle:@"Save link here?"
                                        message:[NSString stringWithFormat:@"Enter a short description of this link for Sen. %@'s notes",selectedLegToSave.name]
                                        delegate:self cancelButtonTitle:@"Cancel"
                                        otherButtonTitles:@"Save",nil];
            saveLinkAlert.alertViewStyle=UIAlertViewStylePlainTextInput;
            answerField = [saveLinkAlert textFieldAtIndex:0];
            answerField.keyboardType = UIKeyboardTypeDefault;
            answerField.placeholder = @"link description";
            [saveLinkAlert show];
            
        }
        //making search view clickable for iphone
        else{
            if (tableView == self.searchDisplayController.searchResultsTableView){
                [self performSegueWithIdentifier:@"SenateSegue" sender:self];
            }
        }
    }
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex==0){
        [self.navigationController popViewControllerAnimated:YES];
    }
    if (buttonIndex ==1){
        
        //reform the note string
        NSString *link=[[NSUserDefaults standardUserDefaults] objectForKey:@"viewForLinkSave"];
        NSString *noteTitle=answerField.text;
        
        NSString * newNoteWithLink = [NSString stringWithFormat:@"%@\n\n%@",noteTitle,link];
        
        
        //get the other data needed for a save
        NSDate *time=[NSDate date];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"M'/'d'/'yyyy' at 'h':'mm' 'a'"];
        NSString *strTime = [formatter stringFromDate:time];
        
        NotesObject * noteSaver = [[NotesObject alloc] init];
        
        noteSaver =[noteSaver makeNewNote:selectedLegToSave];

        noteSaver.timestamp=strTime;
        noteSaver.noteText=newNoteWithLink;
         
        [noteSaver saveNote];
        
        //change the settings to NO.
        //dismiss the view.
        [self.tabBarController dismissViewControllerAnimated:YES completion:nil];
        [[NSUserDefaults standardUserDefaults] setObject:@"NO" forKey:@"viewForLinkSave"];

    }
}


-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    InfoViewController *ivc=[segue destinationViewController];
    NSIndexPath *indexPath = nil;
    NSIndexPath *path = [self.tableView indexPathForSelectedRow];
    
    //Passing info to info view controller
    if ([[segue identifier] isEqualToString: @"SenateSegue"]){
        if ([self.searchDisplayController isActive]) {
            indexPath = [self.searchDisplayController.searchResultsTableView indexPathForSelectedRow];

            Legs *c= [searchResults objectAtIndex:[indexPath row]];
            [ivc setCurrentLeg:c];
        } else {
            Legs *c= [senators objectAtIndex:[path row]];
            [ivc setCurrentLeg:c];
        }
    }
}

-(void)viewDidDisappear:(BOOL)animated{

}
- (IBAction)showLeftMenuPressed:(id)sender {

    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
        if (![[[NSUserDefaults standardUserDefaults] objectForKey:@"viewForLinkSave"] isEqualToString:@"NO"]){
            [self.tabBarController dismissViewControllerAnimated:YES completion:nil];
            [[NSUserDefaults standardUserDefaults] setObject:@"NO" forKey:@"viewForLinkSave"];
        }
        else{
            if (self.barButtonItemPopover.popoverVisible == NO){
                [self.barButtonItemPopover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            }
            else{
                [self.barButtonItemPopover dismissPopoverAnimated:YES];
            }
        }
    }
    else{
        if (![[[NSUserDefaults standardUserDefaults] objectForKey:@"viewForLinkSave"] isEqualToString:@"NO"]){
            [self.tabBarController dismissViewControllerAnimated:YES completion:nil];
            [[NSUserDefaults standardUserDefaults] setObject:@"NO" forKey:@"viewForLinkSave"];
            
        }
        else{
            [self.menuContainerViewController toggleLeftSideMenuCompletion:nil];
        }
    }
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
    [self firstTimeMessage];
    
    //restore notes and vote counts
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        DataLoader *dbCrud=[[DataLoader alloc] init];
        [dbCrud CopyDbToDocumentsFolder];
        [dbCrud DownloadNewPhotos];
        
    });
    
}

// Sent to the delegate when the log in attempt fails.
- (void)logInViewController:(PFLogInViewController *)logInController didFailToLogInWithError:(NSError *)error {
    NSLog(@"Failed to log in...");
}

// Sent to the delegate when the log in screen is dismissed.
- (void)logInViewControllerDidCancelLogIn:(PFLogInViewController *)logInController {
    [self.navigationController popViewControllerAnimated:YES];
    [self firstTimeMessage];
    [PFUser enableAutomaticUser];
    [[PFUser currentUser] saveInBackground];
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
    [self firstTimeMessage];
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
