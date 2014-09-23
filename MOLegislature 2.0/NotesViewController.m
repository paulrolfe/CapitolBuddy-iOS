//
//  NotesViewController.m
//  MOLegislature 3.0
//
//  Created by Paul Rolfe on 3/10/13.
//  Copyright (c) 2013 Paul Rolfe. All rights reserved.
//

#import "NotesViewController.h"

@interface NotesViewController ()

@end

@implementation NotesViewController

@synthesize currentLegNotes;
@synthesize currentNotes, publicLabel, publicSwitchOutlet, downCountLabel, upCountLabel;
@synthesize buttonView, editTextButton, shareButtonText, saveButtonView,saveDateLabel;
@synthesize starCount,starSlidePosition,starImage;
@synthesize currentNoteObject;
@synthesize tagsButtonView, addedUsers;
@synthesize publicToolBar,upVoteView,downVoteView,flagButtonView,publicExplainButtonView;
@synthesize ntvc,antvc;

NSArray *newSenators;
NSArray* newReps;
Legs* reloaded;
NSString *reloadedNote;
NSString *reloadedRating;
NSString *newText;
NSString *currentRating;
CGRect originalTextViewFrame;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
//Create the chat icon

- (void)viewDidLoad
{
    [super viewDidLoad];
    //load these for later:
    newSenators = [[NSArray alloc] initWithArray:[DataLoader database].senators];
    newReps = [[NSArray alloc] initWithArray:[DataLoader database].representatives];

    self.title=@"Note Details";//[NSString stringWithFormat:@"Notes: %@",currentLegNotes.name];
        
    currentNotes.text=currentNoteObject.noteText;
    currentNotes.editable=NO;
    currentNotes.selectable=YES;
    currentNotes.scrollEnabled=YES;
    currentNotes.clipsToBounds=YES;
    
    saveDateLabel.text=[NSString stringWithFormat:@"Saved: %@",currentNoteObject.timestamp];
    [shareButtonText setTitle:@"Edit Sharing Settings" forState:UIControlStateNormal];
    starCount.text=currentLegNotes.rating;
    
    //remove the edit button if note is not editable
    if (!currentNoteObject.isEditable){
        [editTextButton removeFromSuperview];
        self.navigationItem.rightBarButtonItem = nil;
        [shareButtonText setTitle:@"View Sharing Settings" forState:UIControlStateNormal];
        if ([PFAnonymousUtils isLinkedWithUser:[PFUser currentUser]] || ![[PFUser currentUser] isAuthenticated] || currentNoteObject.isPublic)
            [shareButtonText removeFromSuperview];
    }
    if (currentNoteObject.isEditable){
        currentNotes.textContainerInset = UIEdgeInsetsMake(0, 0, 0, 55);
    }
    starSlidePosition.value=[currentLegNotes.rating intValue];
    //remove the slider if the id is not "private", and if it is, remove the sharing, tags, and public views.
    if ([currentNoteObject.objectIDParse isEqualToString:@"private"]){
        [shareButtonText removeFromSuperview];
        [tagsButtonView removeFromSuperview];
        [publicToolBar removeFromSuperview];
        [publicLabel removeFromSuperview];
        [publicSwitchOutlet removeFromSuperview];
    }
    else{
        [starSlidePosition removeFromSuperview];
        [starCount removeFromSuperview];
        [starImage removeFromSuperview];
    }
    
    //if they have voted it down...
    if (currentNoteObject.downVoted){
        //Set the down to inactive and change the color to red.
        [downVoteView setTintColor:[UIColor redColor]];
    }
    //if they have voted it up...
    if (currentNoteObject.upVoted){
        //set the up to inactive and change the color to grey.
        [upVoteView setTintColor:[UIColor greenColor]];
    }
    //if the have flagged it...
    if (currentNoteObject.flagged){
        //set the flag to red.
        [flagButtonView setTintColor:[UIColor redColor]];
    }
    upCountLabel.text=[NSString stringWithFormat:@"%ld",(long)currentNoteObject.upCount];
    downCountLabel.text=[NSString stringWithFormat:@"%ld",(long)currentNoteObject.downCount];

    
    //if you're an editor or if their not logged in, make public tools uninterative. and super gray.
    if (currentNoteObject.isEditable || ![[PFUser currentUser] isAuthenticated] || [PFAnonymousUtils isLinkedWithUser:[PFUser currentUser]]){
        [publicToolBar setHidden:YES];
        [publicExplainButtonView removeFromSuperview];
    }
    // If not public, remove toolbar completely. Also make the public label grey and set as off.
    if (!currentNoteObject.isPublic){
        [publicToolBar removeFromSuperview];
        publicLabel.textColor=[UIColor lightGrayColor];
        [publicSwitchOutlet setOn:NO];
        if (![currentNoteObject.owner.objectId isEqualToString:[PFUser currentUser].objectId]){
            [publicLabel setHidden:YES];
        }
    }
    //if it's public, make the public label be blue and set the on/off
    if (currentNoteObject.isPublic){
        publicLabel.textColor=[UIColor colorWithRed:0 green:.3 blue:.6 alpha:.7];
        [publicSwitchOutlet setOn:YES];
        //if they can't edit the public note (i.e., they CAN vote on it)... make a label that says what the heck to do.
        if (!currentNoteObject.isEditable){
            [publicExplainButtonView setHidden:NO];
            [publicLabel setHidden:YES];
        }
    }
    //if you're not the owner, public switch is gone.
    if (![currentNoteObject.owner.objectId isEqualToString:[PFUser currentUser].objectId]){
        [publicSwitchOutlet setUserInteractionEnabled:NO];
        publicSwitchOutlet.hidden=YES;
    }
    
    self.navigationItem.leftBarButtonItem=nil;
    self.navBar.leftBarButtonItem=nil;
    self.navigationItem.hidesBackButton=NO;
    
    if ([currentNoteObject.objectIDParse isEqualToString:@"newnote"])
        self.navigationItem.rightBarButtonItem.title=@"Unsaved";
    
    
    // Register notifications for when the keyboard appears
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    addedUsers = [[NSMutableArray alloc] init];

}



//keyboard handlers from http://astralbodies.net/blog/2012/02/01/resizing-a-uitextview-automatically-with-the-keyboard/
- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (ntvc){
        if (didSave)
            [ntvc setShouldReloadNotes:YES];
        else
            [ntvc setShouldReloadNotes:NO];
    }
    else if (antvc){
        if (didSave)
            [antvc setShouldReloadNotes:YES];
        else
            [antvc setShouldReloadNotes:NO];
    }
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
            [self.navBar setLeftBarButtonItem:nil
                                     animated:NO];
        else
            [self.navBar setLeftBarButtonItem:nil
                                     animated:NO];
        
        _navigationPaneBarButtonItem = navigationPaneBarButtonItem;
        
        
    }
}

#pragma mark - Keyboard handlers
- (void)keyboardWillShow:(NSNotification*)notification {
    [self moveTextViewForKeyboard:notification up:YES];
}
- (void)keyboardWillHide:(NSNotification*)notification {
    [self moveTextViewForKeyboard:notification up:NO];
    
    //Add the edit button back.
    editTextButton.hidden=NO;
    currentNotes.editable=NO;
    currentNotes.textContainerInset = UIEdgeInsetsMake(0, 0, 0, 55);
    publicToolBar.hidden=NO;

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
    
    [UIView beginAnimations:@"ResizeForKeyboard" context:nil];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];
    
    if (up == YES) {
        CGFloat keyboardTop = keyboardRect.origin.y;
        CGRect newTextViewFrame = currentNotes.frame;
        originalTextViewFrame = currentNotes.frame;
        newTextViewFrame.size.height = keyboardTop;
        currentNotes.frame = newTextViewFrame;
        
    } else {
        
        // Keyboard is going away (down) - restore original frame
        currentNotes.frame = originalTextViewFrame;

        currentNotes.showsVerticalScrollIndicator=YES;
    }
    
    [UIView commitAnimations];

}

//End of keyboard stuff
#pragma mark - Save Handlers
- (IBAction)saveButton:(id)sender {
    didSave=YES;
    [currentNotes resignFirstResponder];
    
    currentNoteObject.noteText=currentNotes.text;
    
    NSDate *time=[NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"M'/'d'/'yyyy' at 'h':'mm' 'a'"];
    NSString *strTime = [formatter stringFromDate:time];
    
    currentNoteObject.timestamp=strTime;
    
    //save to sqlite if it's the rating/custom info type
    if ([currentNoteObject.objectIDParse isEqualToString: @"private"]){
        [self traditionallySaveNote];
    }
    
    //save to Parse if it's a true note object
    else{
        //saving a new note
        if ([currentNoteObject.objectIDParse isEqualToString:@"newnote"]){
            PFObject *note = [PFObject objectWithClassName:@"Notes"];
            note[@"noteText"]=currentNoteObject.noteText;
            note[@"timeStamp"]=currentNoteObject.timestamp;
            note[@"legTags"]=currentNoteObject.legTags;
            note.ACL=currentNoteObject.sharingSettings;
            note[@"writeAccess"]=currentNoteObject.writeAccess;
            if (currentNoteObject.readAccess)
                note[@"readAccess"]=currentNoteObject.readAccess;
            note[@"owner"]=currentNoteObject.owner;
            note[@"savedDate"]=[NSDate date];
            note[@"state"]=[[NSUserDefaults standardUserDefaults]objectForKey:@"state"];
            [note saveInBackgroundWithBlock:^(BOOL succeeded, NSError * error){
            //[note saveEventually:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    //Assign the new objectID to the current note, so you don't accidentally save copies of this note
                    [note refresh];
                    currentNoteObject.objectIDParse=note.objectId;
                    currentNoteObject.pfObject = note;
                    
                    if (addedUsers.count>0){
                        //call a parse function that sends pushes.
                        [PFCloud callFunctionInBackground:@"notePush"
                                           withParameters:@{@"senderUserName" : [PFUser currentUser].username,
                                                            @"newUsers" : addedUsers,
                                                            @"noteID" : currentNoteObject.objectIDParse}
                                                    block:^(NSString *result, NSError *error) {
                                                        if (!error) {
                                                            //NSLog(@"Called a parse function");
                                                            
                                                            addedUsers=[[NSMutableArray alloc] initWithObjects: nil];
                                                        }
                        }];
                    }
                }
                else{
                    [note saveEventually];
                    UIAlertView *tellErr = [[UIAlertView alloc] initWithTitle:@"Unable To Save Note" message:@"You might be offline right now, but your note will save if you restart the app when you have a connection." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [tellErr show];
                }
            }];
        }
        else{
            //saving an existing note.
            currentNoteObject.pfObject[@"noteText"]=currentNoteObject.noteText;
            currentNoteObject.pfObject[@"timeStamp"]=currentNoteObject.timestamp;
            currentNoteObject.pfObject[@"legTags"]=currentNoteObject.legTags;
            currentNoteObject.pfObject.ACL=currentNoteObject.sharingSettings;
            currentNoteObject.pfObject[@"savedDate"]=[NSDate date];
            currentNoteObject.pfObject[@"writeAccess"]=currentNoteObject.writeAccess;
            if (currentNoteObject.readAccess)
                currentNoteObject.pfObject[@"readAccess"]=currentNoteObject.readAccess;
            [currentNoteObject.pfObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                
                if(succeeded){
                    
                    if (addedUsers.count>0){
                        [PFCloud callFunctionInBackground:@"notePush"
                                           withParameters:@{@"senderUserName" : [PFUser currentUser].username,
                                                            @"newUsers" : addedUsers,
                                                            @"noteID" : currentNoteObject.objectIDParse}
                                                    block:^(NSString *result, NSError *error) {
                                                        if (!error) {
                                                            //NSLog(@"Called a parse function");
                                                            addedUsers=[[NSMutableArray alloc] initWithObjects: nil];
                                                        }
                                                    }];
                    }
                }
                if ([error code]==kPFErrorConnectionFailed){
                    [currentNoteObject.pfObject saveEventually];
                    UIAlertView *tellErr = [[UIAlertView alloc] initWithTitle:@"Unable To Save Note" message:@"You might be offline right now, but your note will save if you restart the app when you have a connection." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [tellErr show];
                }
             }];
        }
    }
    
    //Bring back the back button. and say it's saved.
    [self setRightButtonActive:NO];
    
    saveDateLabel.text=[NSString stringWithFormat:@"Saved: %@",currentNoteObject.timestamp];
    
}
-(void) traditionallySaveNote{

    if ([currentLegNotes.hstype isEqualToString:@"S"]){
        DataLoader *dbCrud = [[DataLoader alloc] init];
        newText=self.currentNotes.text;
        int rowToChange=currentLegNotes.rowID;
        NSDate *time=[NSDate date];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"M'/'d'/'yyyy' at 'h':'mm' 'a'"];
        NSString *strTime = [formatter stringFromDate:time];
        int newSyncBool=1;
        NSString *newRating = starCount.text;
        [dbCrud SenateUpdateRecords:newText :strTime :newSyncBool :rowToChange :newRating];
    
        newSenators = [[NSArray alloc] initWithArray:[DataLoader database].senators];

        reloaded = [newSenators objectAtIndex:[currentLegNotes rowID]-1];
        reloadedNote=reloaded.notes;
        saveDateLabel.text=[NSString stringWithFormat:@"Saved: %@",reloaded.timeStamp];

    
        BOOL success=[reloadedNote isEqualToString: newText];
        if (!success){
            UIAlertView *tellErr = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Unable to save." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [tellErr show];
        }
    }
    
    if ([currentLegNotes.hstype isEqualToString:@"H"]){
        DataLoader *dbCrud = [[DataLoader alloc] init];
        newText=self.currentNotes.text;
        int rowToChange=currentLegNotes.rowID;
        NSDate *time=[NSDate date];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"M'/'d'/'yyyy' at 'h':'mm' 'a'"];
        NSString *strTime = [formatter stringFromDate:time];
        int newSyncBool=1;
        NSString *newRating = starCount.text;
        [dbCrud HouseUpdateRecords:newText :strTime :newSyncBool :rowToChange :newRating];
        
        newReps = [[NSArray alloc] initWithArray:[DataLoader database].representatives];
        reloaded = [newReps objectAtIndex:[currentLegNotes rowID]-1];
        
        reloadedNote=reloaded.notes;
        reloadedRating=reloaded.rating;
        saveDateLabel.text=[NSString stringWithFormat:@"Saved: %@",reloaded.timeStamp];
        
        BOOL success=[reloadedNote isEqualToString: newText] && [reloadedRating isEqualToString:newRating];
        if (!success){
            UIAlertView *tellErr = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Unable to save." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [tellErr show];
        }
    }
    
    //Save notes to parse eventually.
    DataLoader *dbCrud=[[DataLoader alloc] init];
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    [defaults synchronize];
    
    NSString *stateFile= [[defaults objectForKey:@"state"]stringByAppendingString:@".sqlite"];
    NSString *crudFileName = [@"crudDBNotes_" stringByAppendingString:stateFile];
    
    NSString *filePath = [dbCrud.GetDocumentDirectory stringByAppendingPathComponent:crudFileName];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    PFFile *file = [PFFile fileWithName:crudFileName data:data];
    [file saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if(error){
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"kShouldDownloadNotes"];
            UIAlertView *tellErr = [[UIAlertView alloc] initWithTitle:@"Unable To Sync With Cloud" message:@"You might be offline right now. Your note will save locally, and you can try saving again when your internet connection returns." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [tellErr show];
        }
        else{
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"kShouldDownloadNotes"];
        }
    }];
    
    //associate the file with the PFUser
    NSString *stateNotes= [NSString stringWithFormat:@"notesFile_%@",[defaults objectForKey:@"state"]];
    [[PFUser currentUser] setObject:file forKey:stateNotes];
    [[PFUser currentUser] saveInBackground];
    
}
-(void)setRightButtonActive:(BOOL)setActive{
    if (setActive){
        [self.navigationItem.rightBarButtonItem setEnabled:YES];
        [self.navigationItem.rightBarButtonItem setTitle:@"Save"];
        
        UIBarButtonItem *newBackButton=[[UIBarButtonItem alloc] initWithTitle:@"Don't Save" style:UIBarButtonItemStyleBordered target:self action:@selector(backWithoutSaving)];
        self.navigationItem.leftBarButtonItem=newBackButton;
    }
    else{
        [self.navigationItem.rightBarButtonItem setEnabled:NO];
        [self.navigationItem.rightBarButtonItem setTitle:@"Saved"];
        
        self.navigationItem.leftBarButtonItem=nil;
        self.navigationItem.hidesBackButton=NO;
    }
}

-(void)buttonToCancel{
    [currentNotes resignFirstResponder];
    self.navigationItem.leftBarButtonItem=nil;
    self.navBar.leftBarButtonItem=nil;
    newText=self.currentNotes.text;
    currentRating=self.starCount.text;
    
    if ([currentLegNotes.hstype isEqualToString:@"S"]){
        newSenators = [[NSArray alloc] initWithArray:[DataLoader database].senators];
        reloaded = [newSenators objectAtIndex:[currentLegNotes rowID]-1];
        
        reloadedNote=reloaded.notes;
        reloadedRating=reloaded.rating;
    }
    if ([currentLegNotes.hstype isEqualToString:@"H"]){
        newReps = [[NSArray alloc] initWithArray:[DataLoader database].representatives];
        reloaded = [newReps objectAtIndex:[currentLegNotes rowID]-1];
        
        reloadedNote=reloaded.notes;
        reloadedRating=reloaded.rating;
    }
    
    if (![reloadedNote isEqualToString: newText]){
        [self setRightButtonActive:YES];
    }
}

-(void)backWithoutSaving{
    NSString *message;
    if ([currentNoteObject.objectIDParse isEqualToString:@"private"])
        message = @"If you leave now, your note and rating will revert to their last saved versions.";
    else
        message = @"If you leave now, your note, tags, and sharing settings will revert to their last saved versions.";
    
    
    UIAlertView *unsavedNote= [[UIAlertView alloc] initWithTitle:@"Unsaved changes" message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [unsavedNote show];
    self.navigationItem.leftBarButtonItem=nil;
    self.navBar.leftBarButtonItem=nil;
    self.navigationItem.hidesBackButton=NO;
    
}

#pragma mark - Sharing Handlers
-(NSString *)getLegislatorNameFromTagArray{
    
    NSMutableString *  resultString = [[NSMutableString alloc] init];
    
    int i=0;
    
    for (NSString * legID in currentNoteObject.legTags){
        
        NSString * district =[legID substringFromIndex:3];
        NSInteger d =[district integerValue];
        
        NSString * HorS = [legID substringToIndex:3];
        HorS=[HorS substringFromIndex:2];
        
        NSString * state = [legID substringToIndex:2];
        
        if (![state isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey:@"state"]]){
            [resultString appendString:legID];
        }
        else if ([HorS isEqualToString:@"H"]){
            [resultString appendString:((Legs *)[newReps objectAtIndex:d-1]).name];
        }
        else if ([HorS isEqualToString:@"S"]){
            [resultString appendString:((Legs *)[newSenators objectAtIndex:d-1]).name];
        }
        i++;
        if (currentNoteObject.legTags.count>i)
            [resultString appendString:@", "];
    }
    return resultString;
}

- (IBAction)sendNote:(id)sender {
    NSString * messageTitle;
    if (currentLegNotes.name)
        messageTitle=[NSString stringWithFormat:@"Notes: %@",currentLegNotes.name];
    if (currentNoteObject.legTags.count>0)
        messageTitle=[NSString stringWithFormat:@"Notes: %@",[self getLegislatorNameFromTagArray]];
    else{
        NSString * filePath = [[DataLoader database].GetDocumentDirectory stringByAppendingPathComponent:@"picDic"];
        NSMutableDictionary * picDic = [[NSMutableDictionary alloc] initWithContentsOfFile:filePath];
        messageTitle=[NSString stringWithFormat:@"Notes from CapitolBuddy user %@",[picDic objectForKey:[currentNoteObject.owner.objectId stringByAppendingString:@"_username"]]];
    }
    NSString *emailBody = [NSString stringWithFormat:@"%@\n (%@)\n\n %@ \n\nMessage sent from CapitolBuddy on iOS, learn more: http://capitolbuddy.com",messageTitle, saveDateLabel.text, currentNotes.text];
    
    ShareActions * sa = [ShareActions actionSheetForItem:currentNoteObject];
    [sa setMessageBody:emailBody];
    [sa setMessageTitle:messageTitle];
    [sa setRootViewController:self];
    [sa showFromToolbar:self.navigationController.toolbar];
}
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
}
-(void) messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Editing Methods
-(void)textViewDidBeginEditing:(UITextView *)textView{
    
    [self setRightButtonActive:YES];
    
    buttonView = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(buttonToCancel)];
    buttonView.tag=45;
    
    self.navigationItem.hidesBackButton=YES;
    self.navigationItem.leftBarButtonItem=buttonView;

}
-(void)textViewDidEndEditing:(UITextView *)textView{
    
}
- (IBAction)starSlider:(id)sender {
    [self setRightButtonActive:YES];
    NSString * starsValue = [NSString stringWithFormat:@"%f",starSlidePosition.value];
    starCount.text = starsValue;
    
        self.navigationItem.leftBarButtonItem=nil;
        UIBarButtonItem *newBackButton=[[UIBarButtonItem alloc] initWithTitle:@"Don't Save" style:UIBarButtonItemStyleBordered target:self action:@selector(backWithoutSaving)];
        self.navigationItem.leftBarButtonItem=newBackButton;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        UIBarButtonItem *newBackButton=[[UIBarButtonItem alloc] initWithTitle:@"Don't Save" style:UIBarButtonItemStyleBordered target:self action:@selector(backWithoutSaving)];
        
        self.navBar.leftBarButtonItem=newBackButton;
    }
}
- (IBAction)editTextButton:(id)sender {
    //Make the button disappear and make the textview begin editing.
    editTextButton.hidden=YES;
    publicToolBar.hidden=YES;
    
    currentNotes.editable=YES;
    currentNotes.textContainerInset=UIEdgeInsetsZero;
    
    [currentNotes becomeFirstResponder];
    
}
- (IBAction)shareButtonClicked:(id)sender {
    //bring up a blank table view and a search table view
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
    SharingViewController * sharePicker = [storyboard instantiateViewControllerWithIdentifier:@"SharingID"];
    UINavigationController *infoNav = [[UINavigationController alloc] initWithRootViewController:sharePicker];
    UIBarButtonItem *backButtonView = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:sharePicker action:@selector(backToNotesButton:)];
    sharePicker.navigationItem.leftBarButtonItem = backButtonView;
    
    
    if (currentNoteObject.isEditable){
        [self setRightButtonActive:YES];
        [sharePicker setIsManager:YES];
    }
    
    [sharePicker setCurrentNote:currentNoteObject];
    [sharePicker setAddedUsers:addedUsers];
    
    [self presentViewController:infoNav animated:YES completion:nil];
    
}
- (IBAction)tagsButtonAction:(id)sender {
    //bring up a blank table view and a search table view
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
    TagPickerViewController * tagPicker = [storyboard instantiateViewControllerWithIdentifier:@"TagPickerID"];
    UINavigationController *infoNav = [[UINavigationController alloc] initWithRootViewController:tagPicker];
    UIBarButtonItem *backButtonView = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:tagPicker action:@selector(backToNotesButton:)];
    tagPicker.navigationItem.leftBarButtonItem = backButtonView;

    
    if (currentNoteObject.isEditable){
        [self setRightButtonActive:YES];
        [tagPicker setIsManager:YES];
    }
    
    [tagPicker setCurrentNote:currentNoteObject];
    
    [self presentViewController:infoNav animated:YES completion:NULL];
}

#pragma mark - Public actions
- (IBAction)publicSwitchAction:(id)sender {
    [self setRightButtonActive:YES];
    
    if (publicSwitchOutlet.on){
        //change note object to public
        currentNoteObject.isPublic=YES;
        publicLabel.textColor=[UIColor colorWithRed:0 green:.3 blue:.6 alpha:.7];
        //change acl
        [currentNoteObject.sharingSettings setPublicReadAccess:YES];
        [currentNoteObject.sharingSettings setPublicWriteAccess:YES];
        //show alert
        UIAlertView * goingPublic = [[UIAlertView alloc] initWithTitle:@"Going Public" message:@"This will make your note readable to all CapitolBuddy users after you save." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [goingPublic show];
    }
    else{
        //change note object to NOT public
        currentNoteObject.isPublic=NO;
        publicLabel.textColor=[UIColor lightGrayColor];
        //change acl
        [currentNoteObject.sharingSettings setPublicReadAccess:NO];
    }

}
- (IBAction)upVoteAction:(id)sender {
    NSString * addSub;
    didSave=YES;
    if (!currentNoteObject.upVoted){//changing it to an up vote.
        //Set the up color to green.
        [upVoteView setTintColor:[UIColor greenColor]];
        //change the upVoted to yes.
        currentNoteObject.upVoted=YES;
        if (currentNoteObject.downVoted){
            currentNoteObject.downVoted=NO;
            downCountLabel.text=[NSString stringWithFormat:@"%ld",(long)[downCountLabel.text integerValue]-1];
        }
        [downVoteView setTintColor:[UIColor lightGrayColor]];
        //increase the counter.
        upCountLabel.text=[NSString stringWithFormat:@"%ld",(long)[upCountLabel.text integerValue]+1];
        addSub=@"add";

    }
    else{//removing the up vote.
        //Set the up color to gray.
        [upVoteView setTintColor:[UIColor lightGrayColor]];
        //change the upVoted to no.
        currentNoteObject.upVoted=NO;
        upCountLabel.text=[NSString stringWithFormat:@"%ld",(long)[upCountLabel.text integerValue]-1];
        addSub=@"subtract";
    }
    //send cloud function to add user as up voter. (and remove down vote)
    [PFCloud callFunctionInBackground:@"changeNoteVotes"
                       withParameters:@{@"senderId" : [PFUser currentUser].objectId,
                                        @"upDown" : @"upVotes",
                                        @"addSubtract" : addSub,
                                        @"noteId" : currentNoteObject.objectIDParse}
                                block:^(NSString *result, NSError *error) {
                                    if (!error) {
                                        NSLog(@"Called a parse function");
                                    }
                                }];
}
- (IBAction)downVoteAction:(id)sender {
    NSString * addSub;
    didSave=YES;
    if (!currentNoteObject.downVoted){//changing to a down vote.
        //Set the down color to red.
        [downVoteView setTintColor:[UIColor redColor]];
        //change the downVoted to yes.
        currentNoteObject.downVoted=YES;
        if (currentNoteObject.upVoted){
            currentNoteObject.upVoted=NO;
            upCountLabel.text=[NSString stringWithFormat:@"%ld",(long)[upCountLabel.text integerValue]-1];
        }
        [upVoteView setTintColor:[UIColor lightGrayColor]];
        //increase the counter.
        downCountLabel.text=[NSString stringWithFormat:@"%ld",(long)[downCountLabel.text integerValue]+1];
        addSub=@"add";
    }
    else{//removing self from down vote.
        //Set the up color to gray.
        [downVoteView setTintColor:[UIColor lightGrayColor]];
        //change the dowVoted to no.
        currentNoteObject.downVoted=NO;
        downCountLabel.text=[NSString stringWithFormat:@"%ld",(long)[downCountLabel.text integerValue]-1];
        addSub=@"subtract";
    }
    [PFCloud callFunctionInBackground:@"changeNoteVotes"
                       withParameters:@{@"senderId" : [PFUser currentUser].objectId,
                                        @"upDown" : @"downVotes",
                                        @"addSubtract" : addSub,
                                        @"noteId" : currentNoteObject.objectIDParse}
                                block:^(NSString *result, NSError *error) {
                                    if (!error) {
                                        NSLog(@"Called a parse function");
                                    }
                                }];
    
}
- (IBAction)flagButtonAction:(id)sender {
    didSave=YES;
    //alert:Do you think this public note is inappropriate or false? Yes, flag it or No, cancel.
    if (!currentNoteObject.flagged){
        UIAlertView * flagAlert = [[UIAlertView alloc] initWithTitle:@"Flag this note?" message:@"If you'd like to report this note as inappropriate or false, click continue." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Continue", nil];
        flagAlert.tag=1;
        [flagAlert show];
    }
    else{
        [currentNoteObject setFlagged:NO];
        [flagButtonView setTintColor:[UIColor lightGrayColor]];
        //call a cloud function to remove the user as a flag.
        
        [PFCloud callFunctionInBackground:@"flagNote"
                           withParameters:@{@"senderId" : [PFUser currentUser].objectId,
                                            @"addSubtract" : @"subtract",
                                            @"noteId" : currentNoteObject.objectIDParse}
                                    block:^(NSString *result, NSError *error) {
                                        if (!error) {
                                            NSLog(@"Called a parse function");
                                        }
                                        else{
                                            [currentNoteObject setFlagged:YES];
                                            [flagButtonView setTintColor:[UIColor redColor]];
                                        }
                                    }];

    }

}
-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (alertView.tag==1){
        if (buttonIndex==1) {
            //change isflagged to yes.
            currentNoteObject.flagged=YES;
            //change the color to red or to not red depending on the color.
            [flagButtonView setTintColor:[UIColor redColor]];

            //send cloud function to add flag/remove flag and send an email to me.
            [PFCloud callFunctionInBackground:@"flagNote"
                               withParameters:@{@"senderId" : [PFUser currentUser].objectId,
                                                @"addSubtract" : @"add",
                                                @"noteId" : currentNoteObject.objectIDParse}
                                        block:^(NSString *result, NSError *error) {
                                            if (!error) {
                                                NSLog(@"Called a parse function");
                                            }
                                            else{
                                                //if error, change the flag color back, the bool back
                                                [currentNoteObject setFlagged:NO];
                                                [flagButtonView setTintColor:[UIColor lightGrayColor]];
                                            }
                                        }];
        }
    }
    
}


- (IBAction)publicExplainButtonAction:(id)sender {
    UIViewController *trueDest = [[UIViewController alloc] init];
    UINavigationController *destNav = [[UINavigationController alloc] initWithRootViewController:trueDest];
    UIWebView * pdfView = [[UIWebView alloc] initWithFrame:trueDest.view.frame];
    
    trueDest.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(dismissViewHelp)];
    trueDest.title=@"About Public Notes";
    
    UISwipeGestureRecognizer * gestureR =[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(dismissViewHelp)];
    gestureR.direction = UISwipeGestureRecognizerDirectionDown;
    [destNav.view addGestureRecognizer:gestureR];
    
    spinnner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(trueDest.view.frame.size.width/2-25, trueDest.view.frame.size.height/2-25, 50, 50)];
    spinnner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    NSURL *targetURL = [NSURL URLWithString:@"http://capitolbuddy.com/about-public-notes"];
    NSURLRequest *request = [NSURLRequest requestWithURL:targetURL];
    pdfView.scalesPageToFit=YES;
    pdfView.delegate=self;
    [trueDest.view addSubview:pdfView];
    [trueDest.view addSubview:spinnner];
    [spinnner startAnimating];
    
    [self presentViewController:destNav animated:YES completion:nil];
    
    [pdfView loadRequest:request];
    
    [pdfView.scrollView setContentOffset:CGPointZero animated:NO];
}
-(void)webViewDidFinishLoad:(UIWebView *)webView{
    [spinnner stopAnimating];
}
-(void) dismissViewHelp{
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
