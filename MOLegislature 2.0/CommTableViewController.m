//
//  CommTableViewController.m
//  MOLegislature 2.0
//
//  Created by Paul Rolfe on 2/26/13.
//  Copyright (c) 2013 Paul Rolfe. All rights reserved.
//

#import "CommTableViewController.h"

@interface CommTableViewController ()

@end

@implementation CommTableViewController

NSArray *allCommittees;
NSArray *committeesSenate;
NSArray *committeesHouse;
NSArray *jointCommittees;
NSArray *searchResultsSenate;
NSArray *searchResultsHouse;
NSArray *searchResultsJoint;


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
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshLegs) forControlEvents:UIControlEventValueChanged];
    
    [super viewDidLoad];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
        SideMenuViewController *content = [storyboard instantiateViewControllerWithIdentifier:@"SideMenu"];
        self.barButtonItemPopover = [[UIPopoverController alloc] initWithContentViewController:content];
        self.barButtonItemPopover.popoverContentSize = CGSizeMake(320., 550.);
        content.barButtonItemPopover = self.barButtonItemPopover;
        content.detailViewManager=(DetailViewManager*)self.splitViewController.delegate;
        self.barButtonItemPopover.delegate = self;
        
    }
    
    [self refreshLegs];
    
    //Set the prompt if in link saving mode.
    if (![[[NSUserDefaults standardUserDefaults] objectForKey:@"viewForLinkSave"] isEqualToString:@"NO"]){
        self.navigationItem.prompt=@"Attach this link to notes by selecting a legislator.";
        self.navigationItem.leftBarButtonItem=nil;
        UIBarButtonItem * backToNews = [[UIBarButtonItem alloc]initWithTitle:@"Back to News" style:UIBarButtonItemStylePlain target:self action:@selector(showLeftMenuPressed:)];
        self.navigationItem.leftBarButtonItem=backToNews;
        
    }
    
}
-(void)refreshLegs{
    //create the lists of committees by H,S, or JC
    allCommittees = [DataLoader database].committees;
    NSPredicate *senateFilter = [NSPredicate predicateWithFormat:@"hsType contains[cd] %@", @"S"];
    committeesSenate = [allCommittees filteredArrayUsingPredicate:senateFilter];
    NSPredicate *houseFilter = [NSPredicate predicateWithFormat:@"hsType like[cd] %@", @"H"];
    committeesHouse = [allCommittees filteredArrayUsingPredicate:houseFilter];
    NSPredicate *jointFilter = [NSPredicate predicateWithFormat:@"hsType like[cd] %@", @"JC"];
    jointCommittees = [allCommittees filteredArrayUsingPredicate:jointFilter];
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];

}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)viewWillAppear:(BOOL)animated{
    
    //create the lists of committees by H,S, or JC
    allCommittees = [DataLoader database].committees;
    NSPredicate *senateFilter = [NSPredicate predicateWithFormat:@"hsType contains[cd] %@", @"S"];
    committeesSenate = [allCommittees filteredArrayUsingPredicate:senateFilter];
    NSPredicate *houseFilter = [NSPredicate predicateWithFormat:@"hsType like[cd] %@", @"H"];
    committeesHouse = [allCommittees filteredArrayUsingPredicate:houseFilter];
    NSPredicate *jointFilter = [NSPredicate predicateWithFormat:@"hsType like[cd] %@", @"JC"];
    jointCommittees = [allCommittees filteredArrayUsingPredicate:jointFilter];
    
    NSString * state = [[NSUserDefaults standardUserDefaults] objectForKey:@"state"];
    self.navigationItem.title = [NSString stringWithFormat:@"%@ Committees",state];
    
    [self.tableView reloadData];
}


- (void)filterContentForSearchText:(NSString*)searchText
{
    NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"commName contains[cd] %@", searchText];
    
    //creating the search arrays from the search text
    searchResultsSenate = [committeesSenate filteredArrayUsingPredicate:resultPredicate];
    searchResultsHouse = [committeesHouse filteredArrayUsingPredicate:resultPredicate];
    searchResultsJoint = [jointCommittees filteredArrayUsingPredicate:resultPredicate];
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
        return 3;

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{

    // Return the number of rows in the section.
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        if (section == 0) {
            return [searchResultsSenate count];
        }
        
        if (section == 1){
            return [searchResultsHouse count];
        }
        if (section == 2) {
            return [searchResultsJoint count];
        }
    }
    if (section == 0) {
        return [committeesSenate count];
    }
    
    if (section == 1){
        return [committeesHouse count];
    }
    if (section == 2){
        return [jointCommittees count];
    }
    else {
        return 50;
    }
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (section == 0) {
        return @"Senate Committees";
    }
    if (section == 1) {
        return @"House Committees";
    }
    if (section ==2) {
        return @"Joint Committees";
    }
    else {
        return @"Error";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CommCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil){
        cell = [[UITableViewCell alloc] init];
    }
    
    //draw the cells for the search results view
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        
        if ([indexPath section]==0) {
            UIFont *smallerFont = [UIFont boldSystemFontOfSize:14];
            cell.textLabel.font=smallerFont;
            CommsClass *current2 =[searchResultsSenate objectAtIndex:[indexPath row]];
            cell.textLabel.text=current2.commName;
            
        }
        if ([indexPath section]==1){
            UIFont *smallerFont = [UIFont boldSystemFontOfSize:14];
            cell.textLabel.font=smallerFont;
            CommsClass * current2 =[searchResultsHouse objectAtIndex:[indexPath row]];
            cell.textLabel.text=current2.commName;
        }
        if ([indexPath section]==2){
            UIFont *smallerFont = [UIFont boldSystemFontOfSize:14];
            cell.textLabel.font=smallerFont;
            CommsClass * current2 =[searchResultsJoint objectAtIndex:[indexPath row]];
            cell.textLabel.text=current2.commName;
        }
    }
    
    //draw the cells for regular view
    else{
    if ([indexPath section]==0) {
        UIFont *smallerFont = [UIFont boldSystemFontOfSize:14];
        cell.textLabel.font=smallerFont;

        CommsClass *current =[committeesSenate objectAtIndex:[indexPath row]];
        cell.textLabel.text=current.commName;
      
    }
    if ([indexPath section]==1) {
        UIFont *smallerFont = [UIFont boldSystemFontOfSize:14];
        cell.textLabel.font=smallerFont;

        CommsClass * current =[committeesHouse objectAtIndex:[indexPath row]];
        cell.textLabel.text=current.commName;
       
    }
    if ([indexPath section]==2) {
        UIFont *smallerFont = [UIFont boldSystemFontOfSize:14];
        cell.textLabel.font=smallerFont;

        CommsClass * current =[jointCommittees objectAtIndex:[indexPath row]];
        cell.textLabel.text=current.commName;
    
    }}
    
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //When the row is selected, perform the segue to Member view
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        [self performSegueWithIdentifier: @"CommSegue" sender: self];
    }

    
}
-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    MemberTableViewController *mtvc=[segue destinationViewController];
    NSIndexPath *path = [self.tableView indexPathForSelectedRow];
    NSIndexPath *indexPath = nil;
    
    //pass the committee name to CurrentComm (a property declared in the Member view controller) from search display view.
    if ([self.searchDisplayController isActive]) {
        indexPath = [self.searchDisplayController.searchResultsTableView indexPathForSelectedRow];
        if ([indexPath section]==0) {
            CommsClass *e= [searchResultsSenate objectAtIndex:[indexPath row]];
            [mtvc setCurrentComm:e];
        }
        if ([indexPath section]==1) {
            CommsClass *f= [searchResultsHouse objectAtIndex:[indexPath row]];
            [mtvc setCurrentComm:f];
        }
        if ([indexPath section]==2) {
            CommsClass *g= [searchResultsJoint objectAtIndex:[indexPath row]];
            [mtvc setCurrentComm:g];
        }

    }
    //pass the committee name to CurrentComm (a property declared in the Member view controller) from normal table view.
    else{
        if ([path section]==0) {
            CommsClass *c= [committeesSenate objectAtIndex:[path row]];
            [mtvc setCurrentComm:c];
        }
        if ([path section]==1) {
            CommsClass *c= [committeesHouse objectAtIndex:[path row]];
            [mtvc setCurrentComm:c];
        }
        if ([path section]==2){
            CommsClass *c= [jointCommittees objectAtIndex:[path row]];
            [mtvc setCurrentComm:c];
        }
    }
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
@end
