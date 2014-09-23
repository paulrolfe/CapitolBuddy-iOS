//
//  VotesTableViewController.m
//  CapitolBuddy
//
//  Created by Paul Rolfe on 9/23/13.
//  Copyright (c) 2013 Paul Rolfe. All rights reserved.
//

#import "VotesTableViewController.h"
#import "MFSideMenu.h"
#import "TallyViewController.h"
#import "GoodVotesViewController.h"
#import "BadVotesViewController.h"
#import "SwingVotesViewController.h"
#import <Parse/Parse.h>

@interface VotesTableViewController ()

@end

@implementation VotesTableViewController
@synthesize editButtonLabel, mySegue;

NSArray * votingBlock;
NSArray * theLegislators;

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
    [self setTitle:@"Vote Count"];
    if (![[PFUser currentUser] isAuthenticated] || [PFAnonymousUtils isLinkedWithUser:[PFUser currentUser]]){
        [self.navigationItem setPrompt:@"Sign in to save Vote Counts"];

    }
}
- (void)viewWillAppear:(BOOL)animated{
     NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    DataLoader * getArrays = [[DataLoader alloc]init];
   
    
    //Load the saved array from sql
    NSArray * savedArrays = [DataLoader database].savedBills;
    
    //Load the originally saved objects in the array
    billsArray = [[NSMutableArray alloc]initWithArray:savedArrays];
    
    //determine the new bill's H or S
    NSString *HSType = [defaults objectForKey:@"newBillHS"];
    if ([HSType isEqualToString:@"H"]){
         votingBlock = [DataLoader database].representatives;
    }
    if ([HSType isEqualToString:@"S"]){
        votingBlock = [DataLoader database].senators;
    }
    
    NSMutableArray* voters = [[NSMutableArray alloc] init];
    for (int i=0; i < [votingBlock count]; i++){
        
        [voters addObject:[NSNumber numberWithInt:i]];
        //NSLog(@"There's object, %i",i);
    }
    [voters addObject:@"711"];
    NSArray *votesB = [NSArray arrayWithObject:[NSNumber numberWithInt:711]];
    NSArray *votesG = [NSArray arrayWithObject:[NSNumber numberWithInt:711]];
    
    if ([defaults objectForKey:@"newBillName"] !=nil){
        
        //Get the new rowID
        VoteTrackers * lastBill = [billsArray lastObject];
        int lastRow = lastBill.uniqueRowID;
        NSLog(@"Last row = %d",lastRow);
        if (lastBill==nil)
            lastRow=0;
        VoteTrackers *newBill = [[VoteTrackers alloc]init];
        
        [newBill setBillName:[defaults objectForKey:@"newBillName"]];
        [newBill setBillHStype:[defaults objectForKey:@"newBillHS"]];
        [newBill setGoodVotes:votesG];
        [newBill setBadVotes:votesB];
        [newBill setSwingVotes:voters];
        [newBill setTargetState:[defaults objectForKey:@"state"]];
        [newBill setUniqueRowID:lastRow+1];
        [billsArray addObject:newBill];
        
        [getArrays InsertNewBill:newBill];
    }
    [defaults setObject:nil forKey:@"newBillName"];
    [defaults setObject:nil forKey:@"newBillHS"];
    [defaults synchronize];
    
    [self.tableView reloadData];
    
    //add a view below the toolbar...
    UILabel * help = [[UILabel alloc] initWithFrame:CGRectMake(20, self.tableView.tableFooterView.frame.origin.y+50, 280, 200)];
    help.text=@"Tap the '+' to create a bill and start keeping track of its votes. Keep a list of swing vote targets, yes votes, and no votes.\n\nChange the order of the vote counts by clicking 'Edit'.";
    help.numberOfLines=0;
    help.lineBreakMode=NSLineBreakByWordWrapping;
    help.tag=446;
    [self.tableView addSubview:help];
}
-(void)viewWillDisappear:(BOOL)animated{
    //insert method for saving the array to Parse
    [[self.view viewWithTag:446] removeFromSuperview];
    
    DataLoader * getFile = [[DataLoader alloc]init];
    
    //Get the votes file
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    [defaults synchronize];
    
    NSString *stateFileLocal= [[defaults objectForKey:@"state"]stringByAppendingString:@".sqlite"];
    NSString *dbFileLocal = [@"SavedBills_" stringByAppendingString:stateFileLocal];
    NSString *cruddatabase = [getFile.GetDocumentDirectory stringByAppendingPathComponent:dbFileLocal];
    
    //Save to Parse as PFFile
    NSData *data = [[NSData alloc]initWithContentsOfFile:cruddatabase];
    PFFile *file = [PFFile fileWithName:dbFileLocal data:data];
    [file saveInBackground];
    
    //Save that PFFile in a Votes class.
    NSString *stateVotesString= [NSString stringWithFormat:@"voteCountFile_%@",[defaults objectForKey:@"state"]];
    [[PFUser currentUser] setObject:file forKey:stateVotesString];
    [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if(error){
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"kShouldDownloadVotes"];
            UIAlertView *tellErr = [[UIAlertView alloc] initWithTitle:@"Unable To Sync With Cloud" message:@"You might be offline right now. Your Vote Count will save locally, and you can try saving again when your internet connection returns." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [tellErr show];
        }
        else{
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"kShouldDownloadVotes"];
        }
    }];
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
    // Return the number of rows in the section.
    return billsArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"BillCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    // Configure the cell...
    VoteTrackers * thisBill =[billsArray objectAtIndex:indexPath.row];
    cell.textLabel.text=thisBill.billName;
    NSString *HorS;
    if ([thisBill.billHStype isEqualToString:@"H"]){
        HorS = @"House";
    }
    if ([thisBill.billHStype isEqualToString:@"S"]){
        HorS = @"Senate";
    }
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ (%@)",HorS, thisBill.targetState];
    return cell;
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    
    return YES;
}



// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        DataLoader * getArrays = [[DataLoader alloc]init];
        VoteTrackers * thisBill =[billsArray objectAtIndex:indexPath.row];

        [getArrays DeleteSavedBills:thisBill.uniqueRowID];
        [billsArray removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}


// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath{
    //reorder the array. then reset the rowId's based on the new indices.
    //the bill being moved
    VoteTrackers * movedBill = [billsArray objectAtIndex:fromIndexPath.row];
    [billsArray removeObjectAtIndex:fromIndexPath.row];
    [billsArray insertObject:movedBill atIndex:toIndexPath.row];
    //for each bill in the new array, delete the old object from the db.
    //then add it back in with the rowId given by its index in our newly edited array
    NSLog(@"Starting updates on vote DB.");

    for (VoteTrackers * bill in billsArray){
        int deleteRow = bill.uniqueRowID;
        [[DataLoader database] DeleteSavedBills:deleteRow];
    }
    int i = 0;
    for (VoteTrackers * bill in billsArray){
        bill.uniqueRowID=i+1;
        [[DataLoader database] InsertNewBill:bill];
        i++;
    }
    
    NSLog(@"Finished updates on vote DB.");
    
    //also update the array. 
}

// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}


/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

- (IBAction)showLeftMenuPressed:(id)sender {
    
    [self.menuContainerViewController toggleLeftSideMenuCompletion:nil];
}

- (IBAction)addButton:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
    UIViewController *newObject = [storyboard instantiateViewControllerWithIdentifier:@"NewBillID"];
    
 
    [self presentViewController:newObject animated:YES completion:NULL];
}

- (IBAction)editButton:(id)sender {
    
    if ([editButtonLabel.title isEqualToString:@"Edit"]) {
        [self.tableView setEditing:YES animated:YES];
        [editButtonLabel setTitle:@"Done"];
    }
    else {
        [self.tableView setEditing:NO animated:YES];
        [editButtonLabel setTitle:@"Edit"];
    }
    
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    NSIndexPath *path = [self.tableView indexPathForSelectedRow];
    VoteTrackers *c= [billsArray objectAtIndex:[path row]];
    
    if ([c.billHStype isEqualToString:@"H"]){
        theLegislators = [DataLoader database].representatives;
    }
    if ([c.billHStype isEqualToString:@"S"]){
        theLegislators = [DataLoader database].senators;
    }
 

    if([segue.identifier isEqualToString:@"billPasser"]){
        
        //pass the info through the Tab Bar Controller
        TallyViewController* vc = [[TallyViewController alloc] init];
        GoodVotesViewController* vc1 = [[GoodVotesViewController alloc]init];
        BadVotesViewController* vc2= [[BadVotesViewController alloc]init];
        SwingVotesViewController* vc3=[[SwingVotesViewController alloc]init];
        
    
        UITabBarController* tbc = [segue destinationViewController];
        
        vc = (TallyViewController *)[[tbc customizableViewControllers] objectAtIndex:0] ;
        //vc1 = (GoodVotesViewController *)[[tbc customizableViewControllers] objectAtIndex:1];
        vc1 = (GoodVotesViewController *)[(UINavigationController *)tbc.viewControllers[1] topViewController];
        //vc2 = (BadVotesViewController *)[[tbc customizableViewControllers] objectAtIndex:3];
        vc2 = (BadVotesViewController *)[(UINavigationController *)tbc.viewControllers[3] topViewController];
        //vc3 = (SwingVotesViewController *)[[tbc customizableViewControllers] objectAtIndex:2];
        vc3 = (SwingVotesViewController *)[(UINavigationController *)tbc.viewControllers[2] topViewController];

        
        [vc setThisBill:c];
        [vc setLegislatorsAll:theLegislators];
        [vc1 setThisBill:c];
        [vc1 setLegislatorsAll:theLegislators];
        [vc2 setThisBill:c];
        [vc2 setLegislatorsAll:theLegislators];
        [vc3 setThisBill:c];
        [vc3 setLegislatorsAll:theLegislators];
    }
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
        
        _navigationPaneBarButtonItem = navigationPaneBarButtonItem;
        
        
    }
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}



@end
