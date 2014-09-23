//
//  EditRSSViewController.m
//  CapitolBuddy
//
//  Created by Paul Rolfe on 12/20/13.
//  Copyright (c) 2013 Paul Rolfe. All rights reserved.
//

#import "EditRSSViewController.h"

@interface EditRSSViewController ()

@end

@implementation EditRSSViewController

@synthesize feedURLs,feedTitles;

NSMutableArray * mutableURLs;
NSMutableArray * mutableTitles;



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
    [self loadRSSList];

}
-(void)viewWillAppear:(BOOL)animated{
    [self loadRSSList];
}

- (void)loadRSSList{
    //load whatever list was loaded on the last screen. Maybe it should be passed in a segue?
    mutableTitles = [NSMutableArray arrayWithArray:feedTitles];
    mutableURLs = [NSMutableArray arrayWithArray:feedURLs];
    
    [self setEditing:YES animated:YES];

    [self.tableView reloadData];
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
    return mutableTitles.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"RSSCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    cell.textLabel.text = [mutableTitles objectAtIndex:indexPath.row];
    cell.detailTextLabel.text= [mutableURLs objectAtIndex:indexPath.row];
    
    return cell;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //remove the objects from the view's data source
        [mutableURLs removeObjectAtIndex:indexPath.row];
        [mutableTitles removeObjectAtIndex:indexPath.row];
        
        //update parse by creating a new string with the current array, without this object.
        NSString * newFeedURLs = [mutableURLs componentsJoinedByString:@";"];
        NSString * newFeedTitles = [mutableTitles componentsJoinedByString:@";"];
        
        //Update Parse
        NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];

        NSString *keyStringURLs = [NSString stringWithFormat:@"stateNews_%@",[defaults objectForKey:@"state"]];
        NSString *keyStringTitles = [NSString stringWithFormat:@"rssTitles_%@",[defaults objectForKey:@"state"]];
        
        
        PFQuery *firstQuery = [PFQuery queryWithClassName:@"News"];
        [firstQuery whereKey:@"userID" equalTo:[PFUser currentUser].objectId];
        [firstQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error){
            
            object[keyStringTitles]=newFeedTitles;
            object[keyStringURLs]=newFeedURLs;
            [object saveInBackground];
            
        }];
        
        
        
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];

        
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    //change the order of the arrays
    NSString * movedTitle = [mutableTitles objectAtIndex:fromIndexPath.row];
    [mutableTitles removeObjectAtIndex:fromIndexPath.row];
    [mutableTitles insertObject:movedTitle atIndex:toIndexPath.row];
    
    NSString *movedURL = [mutableURLs objectAtIndex:fromIndexPath.row];
    [mutableURLs removeObjectAtIndex:fromIndexPath.row];
    [mutableURLs insertObject:movedURL atIndex:toIndexPath.row];
    
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    
    NSString *keyStringURLs = [NSString stringWithFormat:@"stateNews_%@",[defaults objectForKey:@"state"]];
    NSString *keyStringTitles = [NSString stringWithFormat:@"rssTitles_%@",[defaults objectForKey:@"state"]];
    
    NSString * newFeedURLs = [mutableURLs componentsJoinedByString:@";"];
    NSString * newFeedTitles = [mutableTitles componentsJoinedByString:@";"];
    
    //update parse with this new order.
    PFQuery *firstQuery = [PFQuery queryWithClassName:@"News"];
    [firstQuery whereKey:@"userID" equalTo:[PFUser currentUser].objectId];
    [firstQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error){
        
        object[keyStringTitles]=newFeedTitles;
        object[keyStringURLs]=newFeedURLs;
        [object saveInBackground];
        
    }];
    
}


- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    AddFeedViewController *afvc = [segue destinationViewController];
    
    NSString * newFeedURLs = [mutableURLs componentsJoinedByString:@";"];
    NSString * newFeedTitles = [mutableTitles componentsJoinedByString:@";"];
    
    // Pass the selected object to the new view controller.
    [afvc setCurrentTitles:newFeedTitles];
    [afvc setCurrentURLs:newFeedURLs];
    
}


- (IBAction)backButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
