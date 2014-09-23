//
//  APPMasterViewController.m
//  RSSreader
//
//  Created by Rafael Garcia Leiva on 08/04/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import "APPMasterViewController.h"

#import "APPDetailViewController.h"

@interface APPMasterViewController () {
    NSXMLParser *parser;
    NSMutableArray *feeds;
    NSMutableDictionary *item;
    NSMutableString *title;
    NSMutableString *link;
    NSMutableString *description;
    NSString *sectionURL;
    NSString *element;
    NSMutableString *visitedURLs;
    NSArray * feedURLs;
    NSArray * feedTitles;
}
@end

@implementation APPMasterViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)viewDidLoad {
    

    [super viewDidLoad];
    
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    
    //Make the title
    NSString *state = [defaults objectForKey:[defaults objectForKey:@"state"]];
    self.title=[NSString stringWithFormat:@"%@ Capitol News",state];
    
    if (![[PFUser currentUser] isAuthenticated]){
        UIAlertView * pleaseLogIn = [[UIAlertView alloc] initWithTitle:@"Please Log In" message:@"To use this feature you need to first log in as a CapitolBuddy user." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [pleaseLogIn show];
    }
    else{
        self.refreshControl = [[UIRefreshControl alloc] init];
        [self.refreshControl addTarget:self action:@selector(refreshCalled) forControlEvents:UIControlEventValueChanged];
        [self.refreshControl beginRefreshing];
        [self performSelectorInBackground:@selector(refreshCalled) withObject:nil];
    }
}

-(void) viewDidAppear:(BOOL)animated{
    
    [self.tableView reloadData];

}

-(void) refreshCalled{
    
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];

    
    //Load visited Url's into one string.
    visitedURLs = nil;
    DataLoader *stringCrud=[[DataLoader alloc] init];
    NSString * fName = [stringCrud.GetDocumentDirectory stringByAppendingPathComponent:@"VisitedURLs.strings"];
    NSData *data = [NSData dataWithContentsOfFile:fName];
    if (fName) {
        visitedURLs = [NSMutableString stringWithUTF8String:[data bytes]];
    }
     //load the custom list of feeds from parse.
     //find it with a query that checks the news class for the first object that has userID matching the current user's object ID.
    NSString *keyStringURLs = [NSString stringWithFormat:@"stateNews_%@",[defaults objectForKey:@"state"]];
    NSString *keyStringTitles = [NSString stringWithFormat:@"rssTitles_%@",[defaults objectForKey:@"state"]];
    
    PFQuery *firstQuery = [PFQuery queryWithClassName:@"News"];
    firstQuery.cachePolicy=kPFCachePolicyNetworkElseCache;
    [firstQuery whereKey:@"userID" equalTo:[PFUser currentUser].objectId];
    [firstQuery getFirstObjectInBackgroundWithBlock:^(PFObject *newsObject, NSError *error){
     
        NSString * feedURLString = [newsObject objectForKey:keyStringURLs];
        feedURLs = [[NSArray alloc] initWithArray:[feedURLString componentsSeparatedByString:@";"]];
        
        NSString * rssTitleString = [newsObject objectForKey:keyStringTitles];
        feedTitles = [[NSArray alloc] initWithArray:[rssTitleString componentsSeparatedByString:@";"]];
         
        feeds = [[NSMutableArray alloc] init];
             
        //Is there an object there?
        if (feedTitles.count!=0){
            
            //Is the object not blank?
            if (![[feedTitles objectAtIndex:0] isEqualToString:@""]){
                
                for (NSString  * rssURL in feedURLs){
                    NSURL *url = [NSURL URLWithString:rssURL];
                    sectionURL = rssURL;
                    parser = [[NSXMLParser alloc] initWithContentsOfURL:url];
                    [parser setDelegate:self];
                    [parser setShouldResolveExternalEntities:NO];
                    [parser parse];
                }
                
                [self.tableView reloadData];
                [self.refreshControl endRefreshing];

            }
            //If the object is blank, then load the defaults.
            else{
                PFQuery *query = [PFQuery queryWithClassName:@"States"];
                query.cachePolicy=kPFCachePolicyCacheElseNetwork;
                [query whereKey:@"state" equalTo:[defaults objectForKey:@"state"]];
                 
                [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error){
                     
                    //Get the URLs and Titles. And save them to the user's feed.
                    NSString * feedURLString = [object objectForKey:@"senateFeed"];
                    feedURLs = [[NSArray alloc] initWithArray:[feedURLString componentsSeparatedByString:@";"]];
                    
                    NSString * rssTitleString = [object objectForKey:@"rssTitles"];
                    feedTitles = [[NSArray alloc] initWithArray:[rssTitleString componentsSeparatedByString:@";"]];
                    
                    if (![newsObject isDataAvailable]){
                        PFObject *savedFeeds = [PFObject objectWithClassName:@"News"];
                        savedFeeds[keyStringURLs] = feedURLString;
                        savedFeeds[keyStringTitles] = rssTitleString;
                        savedFeeds[@"userID"] = [PFUser currentUser].objectId;
                        [savedFeeds saveInBackground];
                    }
                     
                    feeds = [[NSMutableArray alloc] init];
                     
                    for (NSString  * rssURL in feedURLs){
                        NSURL *url = [NSURL URLWithString:rssURL];
                        sectionURL = rssURL;
                        parser = [[NSXMLParser alloc] initWithContentsOfURL:url];
                        [parser setDelegate:self];
                        [parser setShouldResolveExternalEntities:NO];
                        [parser parse];
                    }
                     
                    [self.tableView reloadData];
                    [self.refreshControl endRefreshing];
                     
                 }];
             }
         }
        
         //if the custom list is nil, load the defaults.
         else{
             PFQuery *query = [PFQuery queryWithClassName:@"States"];
             query.cachePolicy=kPFCachePolicyCacheElseNetwork;
             [query whereKey:@"state" equalTo:[defaults objectForKey:@"state"]];
             [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error){
                 
                 //Get the URLs and Titles. And save them to the user's feed.
                 NSString * feedURLString = [object objectForKey:@"senateFeed"];
                 feedURLs = [[NSArray alloc] initWithArray:[feedURLString componentsSeparatedByString:@";"]];
                 
                 NSString * rssTitleString = [object objectForKey:@"rssTitles"];
                 feedTitles = [[NSArray alloc] initWithArray:[rssTitleString componentsSeparatedByString:@";"]];
                 
                 //If the custom news is not there, make a new one from the defaults.
                 if (![newsObject isDataAvailable]){
                     PFObject *savedFeeds = [PFObject objectWithClassName:@"News"];
                     savedFeeds[keyStringURLs] = feedURLString;
                     savedFeeds[keyStringTitles] = rssTitleString;
                     savedFeeds[@"userID"] = [PFUser currentUser].objectId;
                     [savedFeeds saveInBackground];
                 }
                 
                 feeds = [[NSMutableArray alloc] init];
                 
                 //for each feed url in the array, get the RSS items
                 for (NSString  * rssURL in feedURLs){
                     NSURL *url = [NSURL URLWithString:rssURL];
                     sectionURL = rssURL;
                     parser = [[NSXMLParser alloc] initWithContentsOfURL:url];
                     [parser setDelegate:self];
                     [parser setShouldResolveExternalEntities:NO];
                     [parser parse];
                 }
                 
                 [self.tableView reloadData];
                 [self.refreshControl endRefreshing];
                 
             }];
         }
     }];
}


-(void) searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    
    [self performSegueWithIdentifier:@"showDetail" sender:self];
}
-(void) searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    
    [self.searchBar resignFirstResponder];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSString *) stringByStrippingHTMLfrom:(NSString *)s {
    NSRange r;
    while ((r = [s rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound)
        s = [s stringByReplacingCharactersInRange:r withString:@""];
    return s;
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return feedURLs.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    for (int i=0; i < [feedURLs count]; i++){
        if (section == i){
            //return the count of items whose section name is equal to the current section's name
            NSPredicate * sectionFilter = [NSPredicate predicateWithFormat:@"url contains[cd] %@", [feedURLs objectAtIndex:i]];
            NSArray * sectionItems = [feeds filteredArrayUsingPredicate:sectionFilter];
            
            if (sectionItems.count <= 20 && sectionItems.count>0){
                return sectionItems.count;
            }
            if (sectionItems.count ==0){
                return 1;
            }
            else{
                return 20;
            }
        }
    }
    
    return 0;
}
- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    for (int i=0; i < [feedURLs count]; i++){
        if (section == i){
            //return the section name for the items in this section
            return [feedTitles objectAtIndex:i];
            
        }
    }
    return @"Error";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NewsCell" forIndexPath:indexPath];
    if (cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"NewsCell"];
    }
    
    for (int i=0; i < [feedURLs count]; i++){
        if (indexPath.section == i){
            //return the count of items whose section name is equal to the current section's name
            NSPredicate * sectionFilter = [NSPredicate predicateWithFormat:@"url contains[cd] %@", [feedURLs objectAtIndex:i]];
            NSArray * sectionItems = [feeds filteredArrayUsingPredicate:sectionFilter];
            
            if (sectionItems.count==0){
                cell.textLabel.text = @"Direct Link (No RSS items found)";
                cell.textLabel.font = [UIFont boldSystemFontOfSize:12];
                cell.detailTextLabel.text = [feedURLs objectAtIndex:i];
                cell.textLabel.textColor = [UIColor blackColor];
                cell.detailTextLabel.textColor = [UIColor colorWithRed:0 green:.3 blue:.6 alpha:.7];
                cell.imageView.image = nil;

            }
            else{
                cell.textLabel.text = [[sectionItems objectAtIndex:indexPath.row] objectForKey: @"title"];
                cell.textLabel.font = [UIFont boldSystemFontOfSize:12];
                cell.detailTextLabel.text = [self stringByStrippingHTMLfrom:[[sectionItems objectAtIndex:indexPath.row] objectForKey:@"description"]];
            
            
                //if url of the object at index is contained in the visited url's string... display it in grey text.
                NSPredicate *myPredicate = [NSPredicate predicateWithFormat:@"self contains[cd] %@", [[sectionItems objectAtIndex:indexPath.row] objectForKey:@"link"]];
            
                BOOL match = [myPredicate evaluateWithObject:visitedURLs];
            
                if (match){
                    cell.textLabel.textColor = [UIColor grayColor];
                    cell.detailTextLabel.textColor = [UIColor grayColor];
                    cell.imageView.image = nil;

                }
                else{
                    cell.textLabel.textColor = [UIColor colorWithRed:0 green:.3 blue:.6 alpha:.7];
                    cell.detailTextLabel.textColor = [UIColor colorWithRed:0 green:.3 blue:.6 alpha:.7];
                    cell.imageView.image = [UIImage imageNamed:@"new-word.png"];

                
                }
            }
        }
    }
    
    return cell;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    
    element = elementName;
    

    
    if ([element isEqualToString:@"item"]) {
        
        item    = [[NSMutableDictionary alloc] init];
        title   = [[NSMutableString alloc] init];
        link    = [[NSMutableString alloc] init];
        description = [[NSMutableString alloc]init];

    }

    
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    

    if ([elementName isEqualToString:@"item"]) {
        
        [item setObject:title forKey:@"title"];
        [item setObject:link forKey:@"link"];
        [item setObject:description forKey:@"description"];
        
        [item setObject:sectionURL forKey:@"url"];
        
        [feeds addObject:[item copy]];
        
    }
    
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    
    
    if ([element isEqualToString:@"title"]) {
        [title appendString:string];
    }
    if ([element isEqualToString:@"description"]) {
        [description appendString:string];
    }
    else if ([element isEqualToString:@"link"]) {
        [link appendString:string];
    }
    
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    
    //[self.tableView reloadData];
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        
        for (int i=0; i < [feedURLs count]; i++){
            if (indexPath.section == i){
                //return the count of items whose section name is equal to the current section's name
                NSPredicate * sectionFilter = [NSPredicate predicateWithFormat:@"url contains[cd] %@", [feedURLs objectAtIndex:i]];
                NSArray * sectionItems = [feeds filteredArrayUsingPredicate:sectionFilter];
                
                if (sectionItems.count==0){
                    [[segue destinationViewController] setUrl:[feedURLs objectAtIndex:i]];
                    [[segue destinationViewController] setTitle:[feedTitles objectAtIndex:i]];
                }
    
                else{
                    NSString *string = [sectionItems[indexPath.row] objectForKey: @"link"];
                    NSString *titleString = [sectionItems[indexPath.row] objectForKey: @"title"];

                    [[segue destinationViewController] setUrl:string];
                    [[segue destinationViewController] setTitle:titleString];
        
                    //put the url into list of url's
                    DataLoader *stringCrud=[[DataLoader alloc] init];
        
                    NSString * fName = [stringCrud.GetDocumentDirectory stringByAppendingPathComponent:@"VisitedURLs.strings"];
                    NSError *error;
                    [visitedURLs appendString:string];
                    BOOL ok = [visitedURLs writeToFile:fName atomically:YES encoding:NSUTF8StringEncoding error:&error];
        
                    if (!ok) {
                        NSLog(@"Error writing URL to file.\n%@", [error localizedFailureReason]);
                    }
                }
            }
        }
        if ([self.searchBar isFirstResponder]){
            
            NSString * searchURL = [NSString stringWithFormat:@"https://www.google.com/search?tbm=nws&q=%@",[self.searchBar.text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            
            [[segue destinationViewController] setUrl:searchURL];
            [[segue destinationViewController] setTitle:self.searchBar.text];
        }
    }
    if ([[segue identifier] isEqualToString:@"editFeeds"]) {
        
        EditRSSViewController *ivc=[segue destinationViewController];
        
        [ivc setFeedURLs:feedURLs];
        [ivc setFeedTitles: feedTitles];
    }
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
            [self.navigationItem setLeftBarButtonItem:navigationPaneBarButtonItem
                                     animated:NO];
        else
            [self.navigationItem setLeftBarButtonItem:nil
                                     animated:NO];
        
        _navigationPaneBarButtonItem = navigationPaneBarButtonItem;
        
        
    }
}

@end
