//
//  TagPickerViewController.m
//  CapitolBuddy
//
//  Created by Paul Rolfe on 2/7/14.
//  Copyright (c) 2014 Paul Rolfe. All rights reserved.
//

#import "TagPickerViewController.h"

@interface TagPickerViewController ()

@end

@implementation TagPickerViewController

@synthesize currentNote, isManager;

NSMutableArray * taggedSens;
NSMutableArray * taggedReps;
//NSArray * taggedBills;

NSArray * allSens;
NSArray * allReps;
//NSArray * allBills;



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
    //load all the senators and reps. into a couple arrays
    allSens = [[NSArray alloc] initWithArray:[DataLoader database].senators];
    allReps = [[NSArray alloc] initWithArray:[DataLoader database].representatives];
    
    //load all the bills into an array
    [self.searchDisplayController setSearchResultsDataSource:self];
    
    //Pick which ones are already tagged and assign them to an array.
    taggedSens = [[NSMutableArray alloc] init];
    taggedReps = [[NSMutableArray alloc] init];
    
    for (NSString * legID in currentNote.legTags){
        
        NSString * district =[legID substringFromIndex:3];
        NSInteger d =[district integerValue];

        NSString * HorS = [legID substringToIndex:3];
        HorS=[HorS substringFromIndex:2];
        
        NSString * state = [legID substringToIndex:2];
        
        if (![state isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey:@"state"]]){
            Legs * statePlaceholder = [[Legs alloc] initWithUniqueId:777 name:[NSString stringWithFormat:@"Legislator from %@", state] district:district party:@"Change state to see info" office:@"Unknown" phone:@"Unknown" email:@"Unknown" website:@"Unknown" staff:@"Unknown" hometown:@"Unknown" bio:@"Unknown" notes:@"Unknown" hstype:HorS comms:@"Unknown" imageFile:@"Unknown" timeStamp:@"Unknown" syncBool:0 rating:@"Unknown" leadership:@"Unknown"];
            [taggedSens addObject:statePlaceholder];
        }
        else if ([HorS isEqualToString:@"H"]){
            [taggedReps addObject:[allReps objectAtIndex:d-1]];
        }
        else if ([HorS isEqualToString:@"S"]){
            [taggedSens addObject:[allSens objectAtIndex:d-1]];
        }
        
        
    }
    
    self.title=@"Legislator Tags";
    
    if (!isManager){
        [self.tableView setTableHeaderView:nil];
    }
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (void)filterContentForSearchText:(NSString*)searchText inScope:(NSInteger)scope
{

    
    NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"(name contains[cd] %@) OR (district contains[cd] %@)",searchText, searchText];
    
    switch (scope) {
        case 0:
            if (searchText.length==0)
                searchResults=allSens;
            else
                searchResults = [allSens filteredArrayUsingPredicate:resultPredicate];
            break;
        case 1:
            if (searchText.length==0)
                searchResults=allReps;
            else
                searchResults = [allReps filteredArrayUsingPredicate:resultPredicate];
            break;
        default:
            break;
    }
}

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller
shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString inScope:controller.searchBar.selectedScopeButtonIndex];
    
    return YES;
}
-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption{
    
    [self filterContentForSearchText:controller.searchBar.text inScope:controller.searchBar.selectedScopeButtonIndex];
    
    return YES;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return 1;
    }
    else
        return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return searchResults.count;
    }
    // Return the number of rows in the section.
    if (section==0)
        return taggedSens.count;
    if (section==1)
        return taggedReps.count;
    //if (section==2)
        //return ;
    else
        return 0;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return @"Results";
    }
    else{
        if (section==0)
            return @"Senators";
        if (section==1)
            return @"Representatives";
        //if (section==2)
        //return @"Bills";
        else
            return @"Error";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"TaggerCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    //for retrieving image files
    DataLoader * docGetter = [[DataLoader alloc]init];
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        Legs * current2 = [searchResults objectAtIndex:[indexPath row]];
        [[cell textLabel] setText:[current2 name]];
        cell.detailTextLabel.text=[NSString stringWithFormat:@"(%@) District %@ -- %@",current2.hstype, current2.district, current2.party];
        cell.detailTextLabel.backgroundColor=[UIColor clearColor];
        cell.textLabel.backgroundColor=[UIColor clearColor];
        
        cell.detailTextLabel.textColor=[UIColor colorWithWhite:0.0 alpha:.8];
        
        //retrieve image from local directory.
        NSString *pngName = current2.imageFile;
        NSString *pngPath = [docGetter.GetDocumentDirectory stringByAppendingPathComponent:pngName];
        UIImage *image = [UIImage imageWithContentsOfFile: pngPath];
        
        [[cell imageView] setImage:image];
        if ([current2.party isEqualToString:@"D"]) {
            cell.contentView.backgroundColor = [UIColor colorWithRed:0.1 green:0.3 blue:0.5 alpha:0.6];
        }
        if ([current2.party isEqualToString:@"R"]) {
            cell.contentView.backgroundColor = [UIColor colorWithRed:0.8 green:0.3 blue:0.1 alpha:0.6];
        }
        if ([current2.party isEqualToString:@"I"]){
            cell.contentView.backgroundColor = [UIColor colorWithRed:0.3 green:0.1 blue:0.3 alpha:0.6];
        }
        if ([current2.party isEqualToString:@"NONE"]){
            cell.contentView.backgroundColor = [UIColor whiteColor];
        }
    }
    
    else{
        if ([indexPath section]==0) {
            Legs * info=[taggedSens objectAtIndex:indexPath.row];
            cell.textLabel.text=info.name;
            cell.detailTextLabel.text=[NSString stringWithFormat:@"(%@) District %@ -- %@",info.hstype, info.district, info.party];
            cell.detailTextLabel.textColor=[UIColor colorWithWhite:0.0 alpha:.8];
            
            //Retrieve an image
            NSString *pngName = info.imageFile;
            NSString *pngPath = [docGetter.GetDocumentDirectory stringByAppendingPathComponent:pngName];
            UIImage *image = [UIImage imageWithContentsOfFile: pngPath];
            //Add the image to the table cell
            [[cell imageView] setImage:image];
            
            //Set the cell tint based on d/r
            if ([info.party isEqualToString:@"D"]) {
                cell.contentView.backgroundColor = [UIColor colorWithRed:0.1 green:0.3 blue:0.5 alpha:0.6];
                cell.accessoryView.backgroundColor=[UIColor colorWithRed:0.1 green:0.3 blue:0.5 alpha:0.6];
            }
            if ([info.party isEqualToString:@"R"]) {
                cell.contentView.backgroundColor = [UIColor colorWithRed:0.8 green:0.3 blue:0.1 alpha:0.6];
            }
            if ([info.party isEqualToString:@"I"]){
                cell.contentView.backgroundColor = [UIColor colorWithRed:0.3 green:0.1 blue:0.3 alpha:0.6];
            }
            if ([info.party isEqualToString:@"NONE"]){
                cell.contentView.backgroundColor = [UIColor whiteColor];
            }
        }
        if ([indexPath section]==1) {
            Legs * info=[taggedReps objectAtIndex:indexPath.row];
            cell.textLabel.text=info.name;
            cell.detailTextLabel.text=[NSString stringWithFormat:@"(%@) District %@ -- %@",info.hstype, info.district, info.party];
            cell.detailTextLabel.textColor=[UIColor colorWithWhite:0.0 alpha:.8];
            
            //Retrieve an image
            NSString *pngName = info.imageFile;
            NSString *pngPath = [docGetter.GetDocumentDirectory stringByAppendingPathComponent:pngName];
            UIImage *image = [UIImage imageWithContentsOfFile: pngPath];
            //Add the image to the table cell
            [[cell imageView] setImage:image];
            
            //Set the cell tint based on d/r
            if ([info.party isEqualToString:@"D"]) {
                cell.contentView.backgroundColor = [UIColor colorWithRed:0.1 green:0.3 blue:0.5 alpha:0.6];
                cell.accessoryView.backgroundColor=[UIColor colorWithRed:0.1 green:0.3 blue:0.5 alpha:0.6];
            }
            if ([info.party isEqualToString:@"R"]) {
                cell.contentView.backgroundColor = [UIColor colorWithRed:0.8 green:0.3 blue:0.1 alpha:0.6];
            }
            if ([info.party isEqualToString:@"I"]){
                cell.contentView.backgroundColor = [UIColor colorWithRed:0.3 green:0.1 blue:0.3 alpha:0.6];
            }
            if ([info.party isEqualToString:@"NONE"]){
                cell.contentView.backgroundColor = [UIColor whiteColor];
            }
        }

    /*if ([indexPath section]==2) {
        
        
    }}*/
    }
    
    return cell;
}



// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView != self.searchDisplayController.searchResultsTableView && isManager) {
        return YES;
    }
    else
        return NO;
}


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        if (indexPath.section==0){
            [taggedSens removeObjectAtIndex:indexPath.row];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
        if (indexPath.section==1){
            [taggedReps removeObjectAtIndex:indexPath.row];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }

    }
    //else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    //}
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (tableView==self.searchDisplayController.searchResultsTableView){
        //add the member to the legtags and exit the searchdisplay
        Legs * newTaggedLeg =[searchResults objectAtIndex:indexPath.row];
        
        if ([newTaggedLeg.hstype isEqualToString:@"H"] && ![taggedReps containsObject:newTaggedLeg])
            [taggedReps addObject:newTaggedLeg];
        if ([newTaggedLeg.hstype isEqualToString:@"S"] && ![taggedSens containsObject:newTaggedLeg])
            [taggedSens addObject:newTaggedLeg];
        
        [self.searchDisplayController setActive:NO animated:YES];
        [self.tableView reloadData];
    }
    

}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/
- (IBAction)backToNotesButton:(id)sender {
    //edit the current note's legtags
    
    NSMutableArray * legTags = [[NSMutableArray alloc] init];
    
    for (Legs * sen in taggedSens){
        [legTags addObject:[currentNote createLegIDforLeg:sen]];
    }
    for (Legs * rep in taggedReps){
        [legTags addObject:[currentNote createLegIDforLeg:rep]];
    }
    
    currentNote.legTags=legTags;
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    NotesViewController * nvc = [segue destinationViewController];
    [nvc setCurrentNoteObject:currentNote];
    
}


@end
