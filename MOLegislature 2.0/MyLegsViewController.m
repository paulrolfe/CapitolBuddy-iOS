//
//  MyLegsViewController.m
//  CapitolBuddy
//
//  Created by Paul Rolfe on 3/20/14.
//  Copyright (c) 2014 Paul Rolfe. All rights reserved.
//

#import "MyLegsViewController.h"

@interface MyLegsViewController ()

@end

@implementation MyLegsViewController
@synthesize lookUpMode, lookedUpRep, lookedUpSen, lookedUpState;

NSString * state;
NSString * myState;
NSMutableArray * myLegs;

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
    [self refreshMyLegs];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshMyLegs) forControlEvents:UIControlEventValueChanged];

    //add a button to update address
    if (!lookUpMode){
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"My Address" style:UIBarButtonItemStylePlain target:self action:@selector(showAddressView)];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
            SideMenuViewController *content = [storyboard instantiateViewControllerWithIdentifier:@"SideMenu"];
            self.barButtonItemPopover = [[UIPopoverController alloc] initWithContentViewController:content];
            self.barButtonItemPopover.popoverContentSize = CGSizeMake(320., 550.);
            content.barButtonItemPopover = self.barButtonItemPopover;
            content.detailViewManager=(DetailViewManager*)self.splitViewController.delegate;
            self.barButtonItemPopover.delegate = self;
        }
    }
    if(lookUpMode){
        self.navigationItem.leftBarButtonItem=nil;
        self.title=@"Results";
    }
    
    
}
- (void) viewWillAppear:(BOOL)animated{
    [self refreshMyLegs];
}
-(void) refreshMyLegs{
    //load all the senators and reps. into a couple arrays
    NSArray * allSens = [[NSArray alloc] initWithArray:[DataLoader database].senators];
    NSArray * allReps = [[NSArray alloc] initWithArray:[DataLoader database].representatives];
    
    //load up the correct leg from the legID
    
    NSInteger senD;
    NSInteger repD;
    state = [[NSUserDefaults standardUserDefaults] objectForKey:@"state"];

    if(!lookUpMode){
        myState = [[NSUserDefaults standardUserDefaults] objectForKey:@"myState"];
        senD =[[[NSUserDefaults standardUserDefaults] objectForKey:@"mySen"] integerValue];
        repD =[[[NSUserDefaults standardUserDefaults] objectForKey:@"myRep"] integerValue];
    }
    else{
        myState = lookedUpState;
        senD = [lookedUpSen integerValue];
        repD = [lookedUpRep integerValue];
    }
    
    myLegs = [[NSMutableArray alloc] init];

    
    if (myState==nil){
        UIAlertView * sayhey = [[UIAlertView alloc] initWithTitle:@"Verify info" message:@"We're missing your district info... Please verify your details and click Search." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [sayhey show];
        
        [self showAddressView];
    }
    
    if ([state isEqualToString: myState]){
        //if the loaded state is here.
        [myLegs addObject:[allSens objectAtIndex:senD-1]];
        [myLegs addObject:[allReps objectAtIndex:repD-1]];
    }
    else{
        Legs * fakeSen = [[Legs alloc] initWithUniqueId:777 name:[NSString stringWithFormat:@"Senator from %@-%ld", myState,(long)senD] district:[[NSUserDefaults standardUserDefaults] objectForKey:@"mySen"] party:@"You might be in the wrong state" office:@"Unknown" phone:@"Unknown" email:@"Unknown" website:@"Unknown" staff:@"Unknown" hometown:@"Unknown" bio:@"Unknown" notes:@"Unknown" hstype:@"S" comms:@"Unknown" imageFile:@"Unknown" timeStamp:@"Unknown" syncBool:0 rating:@"Unknown" leadership:@"NONE"];
        [myLegs addObject:fakeSen];
        
        Legs * fakeRep = [[Legs alloc] initWithUniqueId:777 name:[NSString stringWithFormat:@"Representative from %@-%ld", myState, (long)repD] district:[[NSUserDefaults standardUserDefaults] objectForKey:@"myRep"] party:@"You might be in the wrong state" office:@"Unknown" phone:@"Unknown" email:@"Unknown" website:@"Unknown" staff:@"Unknown" hometown:@"Unknown" bio:@"Unknown" notes:@"Unknown" hstype:@"H" comms:@"Unknown" imageFile:@"Unknown" timeStamp:@"Unknown" syncBool:0 rating:@"Unknown" leadership:@"NONE"];
        [myLegs addObject:fakeRep];
    }
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}

-(void) showAddressView{
    //load the teams data and push to the next table.
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
    AddressViewController * teamChooser =[storyboard instantiateViewControllerWithIdentifier:@"AddressID"];
    teamChooser.navigationItem.title=@"Find your Districts";
    [teamChooser setLookUpMode:lookUpMode];
    
    [self.navigationController pushViewController:teamChooser animated:YES];
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
    return 2;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (section == 0) {
        return @"My State Senator";
    }
    if (section == 1) {
        return @"My State Representative";
    }
    else {
        return @"Error";
    }
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    Legs * info;
    if (indexPath.section==0){
        info=[myLegs objectAtIndex:0];
    }
    if (indexPath.section==1){
        info=[myLegs objectAtIndex:1];
    }
    cell.textLabel.text=info.name;
    cell.detailTextLabel.text=[NSString stringWithFormat:@"(%@) District %@ -- %@",info.hstype, info.district, info.party];
    cell.detailTextLabel.backgroundColor=[UIColor clearColor];
    cell.textLabel.backgroundColor=[UIColor clearColor];
    
    cell.detailTextLabel.textColor=[UIColor colorWithWhite:0.0 alpha:.8];
    
    //Retrieve an image
    NSString *pngName = info.imageFile;
    NSString *pngPath = [[DataLoader database].GetDocumentDirectory stringByAppendingPathComponent:pngName];
    UIImage *image = [UIImage imageWithContentsOfFile: pngPath];
    //Add the image to the table cell
    [[cell imageView] setImage:image];
    
    //Set the cell tint based on d/r
    cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
    UIView * myBG = [[UIView alloc] initWithFrame:CGRectZero];
    
    //Set the cell tint based on d/r
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
    
    //Add leadership label
    [[cell.contentView viewWithTag:124] removeFromSuperview];
    if (![info.leadership isEqualToString:@"NONE"]){
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
    
    return cell;
}
- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    InfoViewController * theLegInfo = [self.storyboard instantiateViewControllerWithIdentifier:@"InfoID"];
    [theLegInfo setCurrentLeg:[myLegs objectAtIndex:indexPath.section]];
    [self.navigationController pushViewController:theLegInfo animated:YES];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

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
