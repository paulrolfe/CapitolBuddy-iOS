//
//  MemberTableViewController.m
//  MOLegislature 2.0
//
//  Created by Paul Rolfe on 2/26/13.
//  Copyright (c) 2013 Paul Rolfe. All rights reserved.
//

#import "MemberTableViewController.h"

@interface MemberTableViewController ()

@end

@implementation MemberTableViewController
@synthesize currentComm;
@synthesize fileMgr,homeDir;

NSArray *searchResults;
NSMutableArray *SenHouseCombo;
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

- (void)viewDidLoad
{
    
    
    [super viewDidLoad];
    
    //make the title fit in the top bar
    self.title=currentComm.commName;
    UILabel* tlabel=[[UILabel alloc] initWithFrame:CGRectMake(0,0, 200, 40)];
    tlabel.text=self.title;
    tlabel.textColor=[UIColor blackColor];
    tlabel.font = [UIFont fontWithName:@"Helvetica-Bold" size: 12.0];
    tlabel.numberOfLines=2;
    tlabel.lineBreakMode=NSLineBreakByTruncatingMiddle;
    tlabel.textAlignment=NSTextAlignmentCenter;
    tlabel.backgroundColor =[UIColor clearColor];
    tlabel.adjustsFontSizeToFitWidth=YES;
    self.navigationItem.titleView=tlabel;
    
    //create the array of sens and reps to search
    SenHouseCombo = [[NSMutableArray alloc] initWithArray:[DataLoader database].senators];
    [SenHouseCombo addObjectsFromArray:[DataLoader database].representatives];
    
    //create the array to display "search results"
    NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"comms contains[cd] %@",currentComm.commName];
    searchResults = [SenHouseCombo filteredArrayUsingPredicate:resultPredicate];
    
    if (![[[NSUserDefaults standardUserDefaults] objectForKey:@"viewForLinkSave"] isEqualToString:@"NO"]){
        self.navigationItem.prompt=@"Attach this link to notes by selecting a legislator.";
    }

}
-(void)viewWillAppear:(BOOL)animated{

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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{


    if(searchResults.count>0){
        return [searchResults count];
    }
    else{
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"MemberCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if (cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    //what to do if there are no members found from the search.
    if(searchResults.count==0){
        cell.textLabel.textColor=[UIColor darkGrayColor];
        cell.textLabel.textAlignment=NSTextAlignmentCenter;
        cell.textLabel.text=@"No Members";
        cell.detailTextLabel.text=@"Check the 'Info' if you don't believe me.";
        cell.userInteractionEnabled=NO;
    }
    
    //creating the calls for the committee if there are in fact results.
    else{
    Legs * current2 = [searchResults objectAtIndex:[indexPath row]];

    [[cell textLabel] setText:[current2 name]];
    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"(%@) District %@ -- %@",current2.hstype, current2.district, current2.party]];
    cell.detailTextLabel.textColor=[UIColor colorWithWhite:0.0 alpha:.8];
        
        //retrieve image from local directory.
        NSString *pngName = current2.imageFile;
        NSString *pngPath = [self.GetDocumentDirectory stringByAppendingPathComponent:pngName];
        UIImage *image = [UIImage imageWithContentsOfFile: pngPath];
        [[cell imageView] setImage:image];
        
    //Add cell color based on D or R
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
        
        NSString *chairString=[NSString stringWithFormat:@"%@ (chair",currentComm.commName];
        NSString *viceString=[NSString stringWithFormat:@"%@ (vice",currentComm.commName];
        
        //Add a gavel if the cell has chairman in the name.
        //remove the old ones
        [[cell.contentView viewWithTag:124] removeFromSuperview];
        if ([current2.comms rangeOfString:chairString options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch].location != NSNotFound){
        
            CGRect imageRect = {199,26,70,17};
            UILabel * label = [[UILabel alloc] initWithFrame:imageRect];
            label.textAlignment = NSTextAlignmentCenter;
            label.backgroundColor=[UIColor colorWithWhite:.1 alpha:.5];
            label.textColor = [UIColor whiteColor];
            label.text = @"Chair";
            label.font=[UIFont systemFontOfSize:10];
            label.tag=124;
            [cell.contentView addSubview:label];

        }
        
        //Add a badge if the cell has vice in the name.
        //remove the old ones
        [[cell.contentView viewWithTag:125] removeFromSuperview];
        if ([current2.comms rangeOfString:viceString options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch].location != NSNotFound){
            
            CGRect imageRect = {199,26,70,17};
            UILabel * label = [[UILabel alloc] initWithFrame:imageRect];
            label.textAlignment = NSTextAlignmentCenter;
            label.backgroundColor=[UIColor colorWithWhite:.1 alpha:.5];
            label.textColor = [UIColor whiteColor];
            label.text = @"Vice-Chair";
            label.font=[UIFont systemFontOfSize:10];
            label.tag=125;
            [cell.contentView addSubview:label];
            
        }
    }

    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        [self performSegueWithIdentifier: @"MemberSegue" sender: self];
    }
    if (![[[NSUserDefaults standardUserDefaults] objectForKey:@"viewForLinkSave"] isEqualToString:@"NO"]){
        selectedLegToSave = [searchResults objectAtIndex:indexPath.row];
        
        //Show a popup, asking them to save.
        UIAlertView *saveLinkAlert=[[UIAlertView alloc]
                                    initWithTitle:@"Save link here?"
                                    message:[NSString stringWithFormat:@"Enter a short description of this link for %@'s notes",selectedLegToSave.name]
                                    delegate:self cancelButtonTitle:@"Cancel"
                                    otherButtonTitles:@"Save",nil];
        saveLinkAlert.alertViewStyle=UIAlertViewStylePlainTextInput;
        answerField = [saveLinkAlert textFieldAtIndex:0];
        answerField.keyboardType = UIKeyboardTypeDefault;
        answerField.placeholder = @"link description";
        [saveLinkAlert show];
    }

    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        
        // Get a reference to the DetailViewManager.
        // DetailViewManager is the delegate of our split view.
        DetailViewManager *detailViewManager = (DetailViewManager*)self.splitViewController.delegate;
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"PadStoryboard" bundle:[NSBundle mainBundle]];
        UINavigationController *newDetailNavViewController = [storyboard instantiateViewControllerWithIdentifier:@"InfoNavID"];
        InfoViewController *newDetailViewController = [newDetailNavViewController.viewControllers firstObject];
        
        Legs *c= [searchResults objectAtIndex:[indexPath row]];
        [newDetailViewController setCurrentLeg:c];

        detailViewManager.detailNavigationViewController = newDetailNavViewController;

        
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
    if ([[segue identifier] isEqualToString: @"MemberSegue"]){
        InfoViewController *ivc=[segue destinationViewController];
        NSIndexPath *path = [self.tableView indexPathForSelectedRow];
        Legs *c= [searchResults objectAtIndex:[path row]];
        [ivc setCurrentLeg:c];
    }
    if ([[segue identifier] isEqualToString:@"DetailSegue"]){
         CommDetailsViewController *cdvc=[segue destinationViewController];
        [cdvc setCurrentCommDetail:currentComm];
    }
    
}

- (IBAction)infoButton:(id)sender{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        
        // Get a reference to the DetailViewManager.
        // DetailViewManager is the delegate of our split view.
        DetailViewManager *detailViewManager = (DetailViewManager*)self.splitViewController.delegate;
        
        // Create and configure a new detail view controller appropriate for the selection.
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"PadStoryboard" bundle:[NSBundle mainBundle]];
        UINavigationController *newDetailNavViewController = [storyboard instantiateViewControllerWithIdentifier:@"CommDetailNav"];
        CommDetailsViewController *newDetailViewController = [newDetailNavViewController.viewControllers firstObject];
        
        [newDetailViewController setCurrentCommDetail:currentComm];
        
        detailViewManager.detailNavigationViewController = newDetailNavViewController;
        
        
    }

}



@end
