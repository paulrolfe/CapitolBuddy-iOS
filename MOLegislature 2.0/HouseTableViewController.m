//
//  HouseTableViewController.m
//  MOLegislature 2.0
//
//  Created by Paul Rolfe on 2/26/13.
//  Copyright (c) 2013 Paul Rolfe. All rights reserved.
//

#import "HouseTableViewController.h"

@interface HouseTableViewController ()

@end

@implementation HouseTableViewController
@synthesize representatives;
@synthesize fileMgr,homeDir;

NSArray *searchResults;
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
    

    representatives = [DataLoader database].representatives;
    
    NSString * state = [[NSUserDefaults standardUserDefaults] objectForKey:@"state"];
    self.navigationItem.title = [NSString stringWithFormat:@"%@ House",state];
    
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
    
    [super viewDidLoad];
    representatives = [DataLoader database].representatives;
    /*
    gestureR =[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRecognizer:)];
    gestureR.direction = UISwipeGestureRecognizerDirectionRight;
    [self.tableView addGestureRecognizer:gestureR];
    
    gestureL = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRecognizerLeft:)];
    gestureL.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.tableView addGestureRecognizer:gestureL];
     */
    
    //Set the prompt if in link saving mode.
    if (![[[NSUserDefaults standardUserDefaults] objectForKey:@"viewForLinkSave"] isEqualToString:@"NO"]){
        self.navigationItem.prompt=@"Attach this link to notes by selecting a legislator.";
        self.navigationItem.leftBarButtonItem=nil;
        UIBarButtonItem * backToNews = [[UIBarButtonItem alloc]initWithTitle:@"Back to News" style:UIBarButtonItemStylePlain target:self action:@selector(showLeftMenuPressed:)];
        self.navigationItem.leftBarButtonItem=backToNews;
        
    }

    
}
- (void) viewDidAppear:(BOOL)animated{
    NSString *foo = [NSString stringWithFormat:@"RedOstrich.CapitolBuddy.Universal.%@",[[NSUserDefaults standardUserDefaults] objectForKey:@"state"]];
    if ([[StateIAPHelper sharedInstance] daysRemainingOnSubscriptionForProduct:foo] == 0){
        representatives=nil;
        [[NSUserDefaults standardUserDefaults]setObject:@"RI" forKey:@"state"];
        [[NSUserDefaults standardUserDefaults]synchronize];
    }
}
-(void)refreshLegs{
    representatives = [[NSArray alloc] initWithArray:[DataLoader database].representatives];
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];

}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)filterContentForSearchText:(NSString*)searchText
{
    NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"(name contains[cd] %@) OR (district contains[cd] %@) OR (hometown contains[cd] %@) OR (leadership contains[cd] %@)",searchText, searchText, searchText, searchText];
    
    searchResults = [representatives filteredArrayUsingPredicate:resultPredicate];
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
    if (representatives.count==0){
        return 1;
    }
    else {
        return [representatives count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"HouseCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        Legs * current2 = [searchResults objectAtIndex:[indexPath row]];
        [[cell textLabel] setText:[current2 name]];
        cell.detailTextLabel.text=[NSString stringWithFormat:@"(%@) District %@ -- %@",current2.hstype, current2.district, current2.party];
        cell.detailTextLabel.textColor=[UIColor colorWithWhite:0.0 alpha:.8];
        cell.detailTextLabel.backgroundColor=[UIColor clearColor ];
        cell.textLabel.backgroundColor=[UIColor clearColor];
        
        //retrieve image from local directory.
        NSString *pngName = current2.imageFile;
        NSString *pngPath = [self.GetDocumentDirectory stringByAppendingPathComponent:pngName];
        UIImage *image = [UIImage imageWithContentsOfFile:pngPath];
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
        if (![current2.leadership isEqualToString:@"NONE"] && ![cell.contentView viewWithTag:125]){
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
    else {
        
        if(representatives.count==0){
            cell.textLabel.text=@"Error";
            cell.detailTextLabel.text=@"Please check network connectivity";
            cell.userInteractionEnabled=NO;
        }
        else{
            cell.userInteractionEnabled=YES;
            
            Legs *info=[representatives objectAtIndex:indexPath.row];
            cell.textLabel.text=info.name;
            cell.detailTextLabel.text=[NSString stringWithFormat:@"(%@) District %@ -- %@",info.hstype, info.district, info.party];
            cell.detailTextLabel.textColor=[UIColor colorWithWhite:0.0 alpha:.8];
            //Retrieve an image
            NSString *pngName = info.imageFile;
            NSString *pngPath = [self.GetDocumentDirectory stringByAppendingPathComponent:pngName];
            UIImage *image = [UIImage imageWithContentsOfFile: pngPath];

            //Add the image to the table cell
            [[cell imageView] setImage:image];
            
            /*
            //Get reloaded info
            Legs *info2=[reloadedReps objectAtIndex:indexPath.row];
        
            //Create the chat icon
            CGRect imageRect = {270,3,24,22};
            UIImageView *uiv = [[UIImageView alloc] initWithFrame:imageRect];
            [uiv setImage:[UIImage imageNamed:[NSString stringWithFormat:@"08-chat.png"]]];
            [uiv setClipsToBounds:YES];
            uiv.tag = 976;
        
            //Set chat icon on/off
            if ([buttonTitle.title isEqualToString:@"Hide"]){
                if (info2.syncBool==0){
                    [cell.contentView addSubview:uiv];
                }
                else{
                [[cell.contentView viewWithTag:976] removeFromSuperview];
                }
            }
            if ([buttonTitle.title isEqualToString:@"Unsent Notes"]){
                [[cell.contentView viewWithTag:976] removeFromSuperview];
            }
             */
        
            //Set cell tint based on d/r
            cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
            UIView * myBG = [[UIView alloc] initWithFrame:CGRectZero];
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
            
            
            [[cell.contentView viewWithTag:124] removeFromSuperview];

            if (![info.leadership isEqualToString:@"NONE"] && ![cell.contentView viewWithTag:124]){
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
/*
-(void)swipeRecognizer:(UISwipeGestureRecognizer *)gestureR {
    DataLoader *dbCrud=[[DataLoader alloc] init];
    CGPoint location = [gestureR locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    
    CGRect imageRect = {270,3,24,22};
    UIImageView *uiv = [[UIImageView alloc] initWithFrame:imageRect];
    [uiv setImage:[UIImage imageNamed:[NSString stringWithFormat:@"08-chat.png"]]];
    [uiv setClipsToBounds:YES];
    uiv.tag = 976;
    
    Legs *swipedRow=[reloadedReps objectAtIndex:indexPath.row];
    int swipeYN=swipedRow.syncBool;
    if ([buttonTitle.title isEqualToString:@"Hide"]){
        if(swipeYN==0){
            //Get the cell out of the table view
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        
            //Update the cell or model
            int rowToChange=[indexPath row]+1;
            [dbCrud HouseUpdateBoolOnly:1 :rowToChange];
            reloadedReps = [[NSArray alloc] initWithArray:[DataLoader database].representatives];
            [[cell.contentView viewWithTag:976] removeFromSuperview];
        }
    }
}
-(void)swipeRecognizerLeft:(UISwipeGestureRecognizer *)gestureL {
    DataLoader *dbCrud=[[DataLoader alloc] init];
    CGPoint location = [gestureL locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    
    CGRect imageRect = {270,3,24,22};
    UIImageView *uiv = [[UIImageView alloc] initWithFrame:imageRect];
    [uiv setImage:[UIImage imageNamed:[NSString stringWithFormat:@"08-chat.png"]]];
    [uiv setClipsToBounds:YES];
    uiv.tag = 976;
    
    Legs *swipedRow=[reloadedReps objectAtIndex:indexPath.row];
    int swipeYN=swipedRow.syncBool;
    if ([buttonTitle.title isEqualToString:@"Hide"]){
        if(swipeYN==1){
            //Get the cell out of the table view
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            
            //Update the cell or model
            int rowToChange=[indexPath row]+1;
            [dbCrud HouseUpdateBoolOnly:0 :rowToChange];
            reloadedReps = [[NSArray alloc] initWithArray:[DataLoader database].representatives];
            [cell.contentView addSubview:uiv];
        }
    }
}
 */

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
            Legs *c= [representatives objectAtIndex:[indexPath row]];
            [newDetailViewController setCurrentLeg:c];
            detailViewManager.detailNavigationViewController = newDetailNavViewController;
        }

        if (![[[NSUserDefaults standardUserDefaults] objectForKey:@"viewForLinkSave"] isEqualToString:@"NO"]){
            
            if (tableView == self.searchDisplayController.searchResultsTableView) {
                selectedLegToSave = [searchResults objectAtIndex:indexPath.row];
            }
            else{
                selectedLegToSave = [representatives objectAtIndex:indexPath.row];
            }
            
            UIAlertView *saveLinkAlert=[[UIAlertView alloc]
                                        initWithTitle:@"Save link here?"
                                        message:[NSString stringWithFormat:@"Enter a short description of this link for Rep. %@'s notes",selectedLegToSave.name]
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
                selectedLegToSave = [representatives objectAtIndex:indexPath.row];
            }
            
            //Show a popup, asking them to save.
            UIAlertView *saveLinkAlert=[[UIAlertView alloc]
                                        initWithTitle:@"Save link here?"
                                        message:[NSString stringWithFormat:@"Enter a short description of this link for Rep. %@'s notes",selectedLegToSave.name]
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
                [self performSegueWithIdentifier:@"HouseSegue" sender:self];
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
    if ([[segue identifier] isEqualToString: @"HouseSegue"]){
        if ([self.searchDisplayController isActive]) {
            indexPath = [self.searchDisplayController.searchResultsTableView indexPathForSelectedRow];
        
            Legs *c= [searchResults objectAtIndex:[indexPath row]];
            [ivc setCurrentLeg:c];
        } else {
        
            Legs *c= [representatives objectAtIndex:[path row]];
            [ivc setCurrentLeg:c];
        }
    
    }
}
/*
- (IBAction)notesRefresh:(id)sender {
    
    if ([buttonTitle.title isEqualToString:@"Hide"]){
        reloadedReps=[[NSArray alloc] init];
        reloadedReps=nil;
        
        [self.tableView reloadData];
        buttonTitle.tintColor=[UIColor lightGrayColor];
        buttonTitle.title=@"Unsent Notes";
    }
    else{
        
        reloadedReps=[[NSArray alloc] initWithArray:[DataLoader database].representatives];
        [self.tableView reloadData];
        buttonTitle.title=@"Hide";
        buttonTitle.tintColor=[UIColor colorWithRed:0 green:.3 blue:.6 alpha:.7];
    }
    
}
-(void)viewDidDisappear:(BOOL)animated{
    buttonTitle.title=@"Unsent Notes";
    buttonTitle.tintColor=[UIColor lightGrayColor];
}
 */

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
@end
