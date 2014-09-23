//
//  SideMenuViewController.m
//  MFSideMenuDemo
//
//  Created by Michael Frederick on 3/19/12.

#import "SideMenuViewController.h"
#import "MFSideMenu.h"
#import "VotesTableViewController.h"



@implementation SideMenuViewController

@synthesize detailViewManager, noteAlertCount;

NSArray * menuItems;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}
- (void) viewDidLoad{

    self.title = @"CapitolBuddy";
   
    menuItems = [NSArray arrayWithObjects:@"Legislators", @"Note Feed",@"My Teams", @"Maps",@"District Lookup", @"Vote Count", @"News", @"Options", nil];
}
-(void)viewWillAppear:(BOOL)animated{
    [self loadNoteBadge];
}
-(void)loadNoteBadge{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NotesObject * noteGuru = [[NotesObject alloc] init];
        newNotes = [noteGuru findNewNotesFromAlertsAndSetRead:NO];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //update main thread here.
            int newCount = 0;
            for (NotesObject * note in newNotes){
                if (note.isNew)
                    newCount++;
            }
            noteAlertCount=newCount;
            [self.tableView reloadData];
        });
    });
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return menuItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    NSString *menuText = [menuItems objectAtIndex:indexPath.row];
    cell.textLabel.text=menuText;
    
    if (indexPath.row == 0){//legislators
        //make the image the same size as the others.
        UIImage *image = [UIImage imageNamed:@"government.png"];
        [[cell imageView] setImage:image];
    }
    if (indexPath.row==1){//note feed
        UIImage *image = [UIImage imageNamed:@"Pencil-black.png"];
        [[cell imageView] setImage:image];
        if (noteAlertCount>0){
            CGRect imageRect = {180,10,30,22};
            UIImageView * redDot = [[UIImageView alloc] initWithFrame:imageRect];
            redDot.image=[UIImage imageNamed:@"redDot.png"];
            UILabel *uiv = [[UILabel alloc]initWithFrame:imageRect];
            [uiv setTextAlignment:NSTextAlignmentCenter];
            [uiv setTextColor:[UIColor whiteColor]];
            [uiv setText:[NSString stringWithFormat:@"%d",noteAlertCount]];
            [uiv setClipsToBounds:YES];
            uiv.tag = 123;
            redDot.tag=124;
            //only add the badge if there is no badge present already.
            if (![cell viewWithTag:123] && ![cell viewWithTag:124]){
                [cell addSubview:redDot];
                [cell addSubview:uiv];
            }
        }
        else{
            [[cell viewWithTag:123] removeFromSuperview];
            [[cell viewWithTag:124] removeFromSuperview];
        }
    }
    if (indexPath.row == 2){//my teams
        UIImage *image = [UIImage imageNamed:@"peopleicon.png"];
        [[cell imageView] setImage:image];
    }
    if (indexPath.row == 3){//maps
        UIImage *image = [UIImage imageNamed:@"compass.png"];
        [[cell imageView] setImage:image];
    }
    if (indexPath.row == 4){//lookup
        UIImage *image = [UIImage imageNamed:@"search-01.png"];
        [[cell imageView] setImage:image];
    }
    if (indexPath.row ==5){//vote count
        UIImage *image = [UIImage imageNamed:@"check_box.png"];
        [[cell imageView] setImage:image];
    }
    if (indexPath.row==6){//news
        UIImage *image = [UIImage imageNamed:@"News-icon.png"];
        [[cell imageView] setImage:image];
    }
    if (indexPath.row==7){//options
        UIImage *image = [UIImage imageNamed:@"settings.png"];
        [[cell imageView] setImage:image];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    

    if (indexPath.row==0){//legislators
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            
            [self.barButtonItemPopover dismissPopoverAnimated:YES];
        }
        else{
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
            UITabBarController *destNav = [storyboard instantiateViewControllerWithIdentifier:@"MainTabBar"];
            [self.menuContainerViewController setCenterViewController:destNav];
        }
    }
    if (indexPath.row==1){//notes
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
            AllNotesViewController * trueDest = [storyboard instantiateViewControllerWithIdentifier:@"AllNotes"];
            UINavigationController *detailNavigationController = [[UINavigationController alloc] initWithRootViewController:trueDest];
            [trueDest setBadgeCount:noteAlertCount];
            detailViewManager.detailNavigationViewController = detailNavigationController;
            [self.barButtonItemPopover dismissPopoverAnimated:YES];
        }
        else{
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
            AllNotesViewController * trueDest = [storyboard instantiateViewControllerWithIdentifier:@"AllNotes"];
            UINavigationController *destNav = [[UINavigationController alloc] initWithRootViewController:trueDest];
            [trueDest setBadgeCount:noteAlertCount];
            
            [self.menuContainerViewController setCenterViewController:destNav];
            
        }
    }
    if (indexPath.row==2){//My Teams
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
            TeamManagerViewController * tmvc = [storyboard instantiateViewControllerWithIdentifier:@"TeamManagerID"];
            UINavigationController *destNav = [[UINavigationController alloc] initWithRootViewController:tmvc];
            
            detailViewManager.detailNavigationViewController = destNav;
            [self.barButtonItemPopover dismissPopoverAnimated:YES];
        }
        else{
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
            TeamManagerViewController * tmvc = [storyboard instantiateViewControllerWithIdentifier:@"TeamManagerID"];
            UINavigationController *destNav = [[UINavigationController alloc] initWithRootViewController:tmvc];
            
            tmvc.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu-icon.png"] style:UIBarButtonItemStylePlain target:tmvc action:@selector(showLeftMenuPressed:)];
            
            [self.menuContainerViewController setCenterViewController:destNav];
        }
    }

    if (indexPath.row==3){//maps
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            // Create and configure a new detail view controller appropriate for the selection.
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
            NewMapViewController * senateMap = [storyboard instantiateViewControllerWithIdentifier:@"NewMapID"];
            UINavigationController *detailNavigationController = [[UINavigationController alloc] initWithRootViewController:senateMap];
            
            detailViewManager.detailNavigationViewController = detailNavigationController;
            [self.barButtonItemPopover dismissPopoverAnimated:YES];
            
        }
        else{
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
            NewMapViewController * senateMap = [storyboard instantiateViewControllerWithIdentifier:@"NewMapID"];
            UINavigationController *destNav = [[UINavigationController alloc] initWithRootViewController:senateMap];
            [self.menuContainerViewController setCenterViewController:destNav];
        }
    }
    if (indexPath.row==4){//search
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            // Create and configure a new detail view controller appropriate for the selection.
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"PadStoryboard" bundle:[NSBundle mainBundle]];
            AddressViewController * myLegs = [storyboard instantiateViewControllerWithIdentifier:@"AddressID"];
            UINavigationController *destNav = [[UINavigationController alloc] initWithRootViewController:myLegs];
            [myLegs setLookUpMode:YES];
            
            detailViewManager.detailNavigationViewController = destNav;
            [self.barButtonItemPopover dismissPopoverAnimated:YES];
            
        }
        else{
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
            AddressViewController * myLegs = [storyboard instantiateViewControllerWithIdentifier:@"AddressID"];
            UINavigationController *destNav = [[UINavigationController alloc] initWithRootViewController:myLegs];
            [myLegs setLookUpMode:YES];
            [self.menuContainerViewController setCenterViewController:destNav];
        }
    }
    if (indexPath.row == 5){//Vote Count
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"PadStoryboard" bundle:[NSBundle mainBundle]];
            UINavigationController *detailNavigationController = [storyboard instantiateViewControllerWithIdentifier:@"TopNavID"];
            
            detailViewManager.detailNavigationViewController = detailNavigationController;
            [self.barButtonItemPopover dismissPopoverAnimated:YES];
        }
        else{
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
            UINavigationController *destNav = [storyboard instantiateViewControllerWithIdentifier:@"TopNavID"];
            [self.menuContainerViewController setCenterViewController:destNav];
        }
    }
    if (indexPath.row==6){//News
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"PadStoryboard" bundle:[NSBundle mainBundle]];
            UINavigationController *detailNavigationController = [storyboard instantiateViewControllerWithIdentifier:@"NewsNavID"];
            
            detailViewManager.detailNavigationViewController = detailNavigationController;
            [self.barButtonItemPopover dismissPopoverAnimated:YES];
        }
        else{
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
            UINavigationController *destNav = [storyboard instantiateViewControllerWithIdentifier:@"NewsNavID"];
            [self.menuContainerViewController setCenterViewController:destNav];
        }
    }
    
    if (indexPath.row == 7){//Options
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
            UINavigationController *detailNavigationController = [storyboard instantiateViewControllerWithIdentifier:@"OptionsNavID"];
            
            detailViewManager.detailNavigationViewController = detailNavigationController;
            [self.barButtonItemPopover dismissPopoverAnimated:YES];
        }
        else{
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
            UINavigationController *destNav = [storyboard instantiateViewControllerWithIdentifier:@"OptionsNavID"];
            [self.menuContainerViewController setCenterViewController:destNav];
        }
    }
    
    [self.menuContainerViewController setMenuState:MFSideMenuStateClosed];
}




- (IBAction)inviteButton:(id)sender {
    //Bring up the address book, let them choose people that have email addresses.
    ABPeoplePickerNavigationController *picker =
    [[ABPeoplePickerNavigationController alloc] init];
    picker.peoplePickerDelegate = self;
    
    [self presentViewController:picker animated:YES completion:nil];
    picker.navigationBar.topItem.prompt=@"Who should we invite?";
}
- (IBAction)rateButton:(id)sender {
    #define YOUR_APP_STORE_ID 704742884 //Change this one to your ID
    
    static NSString *const iOS7AppStoreURLFormat = @"itms-apps://itunes.apple.com/app/id%d";
    static NSString *const iOSAppStoreURLFormat = @"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%d";
    
    NSURL * theUrl = [NSURL URLWithString:[NSString stringWithFormat:([[UIDevice currentDevice].systemVersion floatValue] >= 7.0f)? iOS7AppStoreURLFormat: iOSAppStoreURLFormat, YOUR_APP_STORE_ID]]; // Would contain the right link
    [[UIApplication sharedApplication] openURL:theUrl];
}
- (IBAction)supportTapped:(id)sender {
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
- (void)peoplePickerNavigationControllerDidCancel:
(ABPeoplePickerNavigationController *)peoplePicker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (BOOL)peoplePickerNavigationController:
(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person {
    [self dismissViewControllerAnimated:YES completion:nil];
    ABMutableMultiValueRef emailRef = ABRecordCopyValue(person, kABPersonEmailProperty);
    email = (__bridge NSString *)ABMultiValueCopyValueAtIndex(emailRef, 0);
    
    UIAlertView * confirm = [[UIAlertView alloc] initWithTitle:@"Confirmation" message:[NSString stringWithFormat:@"Shall we send an email invitation to join CapitolBuddy to %@",email] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Send", nil];
    confirm.tag=67;
    [confirm show];
    
    return NO;
}
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (alertView.tag==67 && buttonIndex==1){
        [self sendParseInvite];
    }
}
- (BOOL)peoplePickerNavigationController:
(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person
                                property:(ABPropertyID)property
                              identifier:(ABMultiValueIdentifier)identifier
{
    
    return NO;
}
-(void)sendParseInvite{
    
    [PFCloud callFunctionInBackground:@"inviteEmail"
                       withParameters:@{@"sender" : [PFUser currentUser].username,
                                        @"sendTo" : email}
                                block:^(NSString *result, NSError *error) {
                                    if (!error) {
                                        NSLog(@"Email sent!");
                                        //Show a grey checkmark or something.
                                        [self popupImage];
                                        
                                    }
                                    else{
                                        UIAlertView * noEmailSent = [[UIAlertView alloc] initWithTitle:@"Error" message:[error userInfo][@"error"] delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
                                        [noEmailSent show];
                                    }
                                }];
}
-(void)popupImage
{
    if (check==nil){
        check = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"check.png"]];
        check.frame = CGRectMake(self.view.frame.size.width/2-50, self.view.frame.size.height/2-50, 100, 100);
        check.tintColor=[UIColor grayColor];
        check.backgroundColor=[UIColor lightGrayColor];
        [self.view addSubview:check];
    }

    check.hidden = NO;
    check.alpha = 0.8f;
    // Then fades it away after 2 seconds (the cross-fade animation will take 0.5s)
    [UIView animateWithDuration:0.5 delay:2.0 options:0 animations:^{
        // Animate the alpha value of your imageView from 1.0 to 0.0 here
        check.alpha = 0.0f;
    } completion:^(BOOL finished) {
        // Once the animation is completed and the alpha has gone to 0.0, hide the view for good
        check.hidden = YES;
    }];
}

@end