//
//  NotesTableViewController.m
//  CapitolBuddy
//
//  Created by Paul Rolfe on 1/19/14.
//  Copyright (c) 2014 Paul Rolfe. All rights reserved.
//

#import "NotesTableViewController.h"

@interface NotesTableViewController ()

@end

@implementation NotesTableViewController

@synthesize currentLegNotes,currentLegNew;
@synthesize publicNotes, allNotes, myNotes, shouldReloadNotes;

NSArray *newSenators;
NSArray* newReps;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.scrollsToTop=YES;
        
    if (![[PFUser currentUser] isAuthenticated] || [PFAnonymousUtils isLinkedWithUser:[PFUser currentUser]]){
        //tell them what's up if they're anon or not logged in.
        [self.navigationItem.rightBarButtonItem setEnabled:NO];
        notLoggedIn=YES;
    }
    shouldReloadNotes=YES;
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(loadNetworkNotes) forControlEvents:UIControlEventValueChanged];
    filePath = [[DataLoader database].GetDocumentDirectory stringByAppendingPathComponent:@"picDic"];
    picDic = [[NSMutableDictionary alloc] initWithContentsOfFile:filePath];
    
    //load the cached results if you've got them to start, and then let the updated notes come in.
    [self loadCachedNotes];

    //create title label
    self.title=[NSString stringWithFormat:@"Notes: %@",currentLegNotes.name];
    UILabel* tlabel=[[UILabel alloc] initWithFrame:CGRectMake(0,0, 200, 40)];
    tlabel.text=self.title;
    tlabel.textColor=[UIColor blackColor];
    tlabel.font = [UIFont fontWithName:@"Helvetica-Bold" size: 15.0];
    tlabel.textAlignment = NSTextAlignmentCenter;
    tlabel.backgroundColor =[UIColor clearColor];
    tlabel.adjustsFontSizeToFitWidth=YES;
    self.navigationItem.titleView=tlabel;
}

-(void) viewWillAppear:(BOOL)animated{
    if (shouldReloadNotes){
        [self refreshLocalNotes];
        [self.refreshControl beginRefreshing];
        [self loadNetworkNotes];
    }
    else{
        [self.tableView reloadData];
    }
}

-(void) loadCachedNotes{
    NotesObject * noteGuru = [[NotesObject alloc] init];
    allNotes =[noteGuru findMyNotesForLeg:currentLegNew withCachePolicy:kPFCachePolicyCacheOnly];
    [self refreshParseNotes];
}
-(void) loadNetworkNotes{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NotesObject * noteGuru = [[NotesObject alloc] init];
        allNotes =[noteGuru findMyNotesForLeg:currentLegNew withCachePolicy:kPFCachePolicyNetworkElseCache];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //update main thread here.
            [self refreshParseNotes];
            [self downloadProfilePics];
        });
    });
}

-(void) refreshLocalNotes{
    //reload the custom info
    if([currentLegNotes.hstype isEqualToString:@"S"]){
        newSenators = [[NSArray alloc] initWithArray:[DataLoader database].senators];
        currentLegNew = [newSenators objectAtIndex:[currentLegNotes rowID]-1];
    }
    if([currentLegNotes.hstype isEqualToString:@"H"]){
        newReps = [[NSArray alloc] initWithArray:[DataLoader database].representatives];
        currentLegNew = [newReps objectAtIndex:[currentLegNotes rowID]-1];
    }
}
-(void) refreshParseNotes{
    
    myNotes = [[NSMutableArray alloc] init];
    publicNotes = [[NSMutableArray alloc] init];
    
    //reload the list of notes.
    NSLog(@"total note count:%lu",(unsigned long)allNotes.count);
    
    for (NotesObject * note in allNotes){
        if (note.isPublic){
            [publicNotes addObject:note];
        }
        if ([note.sharingSettings getReadAccessForUser:[PFUser currentUser]]){
            [myNotes addObject:note];
        }
    }
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"upCount" ascending:NO];
    [publicNotes sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];

    
    [self.refreshControl endRefreshing];
    [self.tableView reloadData];
}
-(void)downloadProfilePics{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        if (picDic ==nil)
            picDic = [[NSMutableDictionary alloc] init];
        for (NotesObject * note in allNotes){//go through each owner in allnotes
            if (![picDic.allKeys containsObject:note.owner.objectId] || [(NSDate *)[picDic objectForKey:[note.owner.objectId stringByAppendingString:@"_date"]] timeIntervalSinceNow]<-60*60*24){//if there is no data yet... or it hasn't been updated in 24 hours.
                [note.owner fetchIfNeeded];
                PFFile * imageFile = note.owner[@"imageFile"];
                if (note.owner[@"imageFile"]!=nil){
                    NSData * data = [self resizeProfileImage:[imageFile getData]];
                    [picDic setObject:data forKey:note.owner.objectId];
                    //also get the username and real name for the cell views.
                    [picDic setObject:[NSDate date] forKey:[note.owner.objectId stringByAppendingString:@"_date"]];
                    [picDic setObject:note.owner.username forKey:[note.owner.objectId stringByAppendingString:@"_username"]];
                    [picDic setObject:note.owner[@"realName"] forKey:[note.owner.objectId stringByAppendingString:@"_realname"]];
                    
                    
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //update main thread here.
            [picDic writeToFile:filePath atomically:YES];
            [self.tableView reloadData];
        });
    });
    
}
-(NSData *) resizeProfileImage:(NSData *)imageData{
    UIImage * imageProfile = [UIImage imageWithData:imageData];
    CGFloat realHeight = imageProfile.size.height;
    CGFloat realWidth = imageProfile.size.width;
    CGFloat newWidth = 100;
    CGFloat newHeight = (100 * realHeight)/realWidth;
    
    CGSize newSize=CGSizeMake(newWidth, newHeight);
    UIGraphicsBeginImageContext( newSize );
    [imageProfile drawInRect:CGRectMake(0,0,newWidth,newHeight)];
    
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    NSData * newData = UIImageJPEGRepresentation(newImage, 1);
    
    return newData;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 3;
}
-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    if (section==2){
        if (footerView==nil){
            footerView = [[UIView alloc] init];
            
            //create the button
            UILabel * help = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2-140, 3, 280, 200)];
            help.text=@"Tap the '+' to create a new note. Or browse the public notes where you can up vote or down vote information.";
            help.numberOfLines=0;
            help.lineBreakMode=NSLineBreakByWordWrapping;
            help.tag=446;
            [footerView addSubview:help];
            //return the view for the footer
        }
        return footerView;
    }
    else
        return nil;
}
-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    if (section==2)
        return 200;
    else
        return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    //actually return the number of notes, but we'll do one for now. [filterednotesarray.count]
    if (section==0){
        return 1;
    }
    if (section ==1){//my notes
        if (notLoggedIn)
            return 1;
        else
            return myNotes.count;
    }
    if (section==2){//public notes
        return publicNotes.count;
    }
    else{
        return 0;
    }
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (section==0){
        return @"Rating & Custom Info";
    }
    if (section ==1){
        return @"My notes";
    }
    if (section==2){
        return @"Public Notes";
    }
    else{
        return @"error";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    // Configure the cell...

    if (indexPath.section == 0){
        static NSString *CellIdentifier = @"Cell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil){
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        }
        
        cell.textLabel.text = currentLegNew.notes;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"Last save: %@",currentLegNew.timeStamp];
        cell.imageView.image=[UIImage imageNamed:@"BlackStar.PNG"];
        
        UILabel * rlabel = [[UILabel alloc] initWithFrame:CGRectMake(18, 17, 11, 13)];
        rlabel.text=currentLegNew.rating;
        rlabel.textColor=[UIColor whiteColor];
        rlabel.tag=9;
        //remove the old label
        [[cell.contentView viewWithTag:9] removeFromSuperview];
        //add the new label
        [cell.imageView addSubview:rlabel];
        
        return cell;
    }
    
    static NSString *CustomCell = @"PublicCell";
    BigNoteCell * cell=(BigNoteCell *)[tableView dequeueReusableCellWithIdentifier:CustomCell];
    if (cell == nil){
        cell = [[BigNoteCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CustomCell];
    }
    NotesObject * noteInfo;
    
    if (indexPath.section ==1){//My notes
        if (notLoggedIn){
            
            if (logInButton==nil){
                CGRect theFrame = CGRectMake(cell.noteTextLabel.frame.origin.x, cell.usernameLabel.frame.origin.y+cell.usernameLabel.frame.size.height+8, cell.noteTextLabel.frame.size.width,44);
                logInButton = [[UIButton alloc] initWithFrame:theFrame];
                logInButton.backgroundColor=[UIColor colorWithRed:0 green:.3 blue:.6 alpha:.7];
                [logInButton setTitle:@"log in / sign up" forState:UIControlStateNormal];
                [logInButton addTarget:self action:@selector(showLogIn) forControlEvents:UIControlEventTouchUpInside];
                [cell.contentView addSubview:logInButton];
            }
            
            cell.accessoryType=UITableViewCellAccessoryNone;
            cell.selectionStyle=UITableViewCellSelectionStyleNone;
            [cell.noteTextLabel setText:@""];
            cell.usernameLabel.text=@"Log in to make new notes";
            cell.usernameLabel.lineBreakMode=NSLineBreakByClipping;
            cell.profileImageView.image=[UIImage imageNamed:@"capbud_152.png"];
            cell.readOnlyView.hidden=YES;
            [cell setArrowsVisible:NO];
            return cell;
        }
        else{
            noteInfo=[myNotes objectAtIndex:indexPath.row];
        }
    }
    if (indexPath.section==2){//Public Notes
        noteInfo = [publicNotes objectAtIndex:indexPath.row];
    }
    
    cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;

    //Arrows or no arrows.
    if (noteInfo.isPublic)
        [cell setArrowsVisible:YES];
    else
        [cell setArrowsVisible:NO];
    
    if (noteInfo.isPublic)
        [cell setArrowsVisible:YES];
    if (!noteInfo.isPublic)
        [cell setArrowsVisible:NO];
    if (noteInfo.isEditable)
        cell.readOnlyView.imageView.image=[UIImage imageNamed:@"Pencil-black.png"];
    if (!noteInfo.isEditable)
        cell.readOnlyView.imageView.image=[UIImage imageNamed:@"eye-01.png"];
    if (noteInfo.writeAccess.count>1 || noteInfo.readAccess.count>1)
        cell.sharedButtonView.hidden=NO;
    if (!(noteInfo.writeAccess.count>1) && !(noteInfo.readAccess.count>1))
        cell.sharedButtonView.hidden=YES;
    
    cell.usernameLabel.text = [picDic objectForKey:[noteInfo.owner.objectId stringByAppendingString:@"_username"]];
    cell.realnameLabel.text = [picDic objectForKey:[noteInfo.owner.objectId stringByAppendingString:@"_realname"]];
    cell.noteTextLabel.text = noteInfo.noteText;
    cell.timeLabel.text=[noteInfo timeSinceLastSave];
    cell.upCountCellLabel.text=[NSString stringWithFormat:@"%ld",(long)noteInfo.upCount];
    cell.downCountCellLabel.text=[NSString stringWithFormat:@"%ld",(long)noteInfo.downCount];
    UIImage * profileImage = [[UIImage alloc] initWithData:[picDic objectForKey:noteInfo.owner.objectId]];
    if (profileImage!=nil)
        cell.profileImageView.image=profileImage;

    
    return cell;
}
-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (!indexPath.section==0)
        return 82;
    else
        return 44;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    UIStoryboard * storyboard;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        storyboard = [UIStoryboard storyboardWithName:@"PadStoryboard" bundle:[NSBundle mainBundle]];
    }
    else{
        storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
    }
    NotesViewController * ivc = [storyboard instantiateViewControllerWithIdentifier:@"NoteViewID"];
    [ivc setCurrentLegNotes:currentLegNew];
    [ivc setNtvc:self];
    
    if (indexPath.section==0){
        NotesObject * notesGuru = [[NotesObject alloc]init];
        [ivc setCurrentNoteObject:[notesGuru noteFromLeg:currentLegNew]];
    }
    if (indexPath.section==1){
        if (notLoggedIn)
            return;
        else
            [ivc setCurrentNoteObject:[myNotes objectAtIndex:indexPath.row]];
    }
    if (indexPath.section==2){
        [ivc setCurrentNoteObject:[publicNotes objectAtIndex:indexPath.row]];
    }
    [self.navigationController pushViewController:ivc animated:YES];
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    if (indexPath.section==1 && !notLoggedIn)
        return YES;
    else
        return NO;
}



// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        if (indexPath.section==1){
            NotesObject * noteToDelete = [[NotesObject alloc] init];
            noteToDelete = [myNotes objectAtIndex:indexPath.row];
            [noteToDelete deleteNote];
            [myNotes removeObjectAtIndex:indexPath.row];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}


#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{

    if ([[segue identifier] isEqualToString: @"NewNoteSegue"]){
        NotesViewController *ivc=[segue destinationViewController];
        [ivc setCurrentLegNotes:currentLegNew];
        
        NotesObject * notesGuru = [[NotesObject alloc]init];
        [ivc setCurrentNoteObject:[notesGuru makeNewNote:currentLegNew]];
    }
}

-(void)showLogIn{
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
    notLoggedIn=NO;
    [logInButton removeFromSuperview];
    [self.navigationItem.rightBarButtonItem setEnabled:YES];
    [self.tableView reloadData];
    
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
    [self dismissViewControllerAnimated:YES completion:nil];
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
    notLoggedIn=NO;
    [logInButton removeFromSuperview];
    [self dismissViewControllerAnimated:YES completion:NULL];
    [self.navigationItem.rightBarButtonItem setEnabled:YES];
    [self reloadInputViews];
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
