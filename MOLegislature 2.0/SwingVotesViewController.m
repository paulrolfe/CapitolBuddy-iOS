//
//  SwinsVotesViewController.m
//  CapitolBuddy
//
//  Created by Paul Rolfe on 9/24/13.
//  Copyright (c) 2013 Paul Rolfe. All rights reserved.
//

#import "SwingVotesViewController.h"
#import "InfoViewController.h"

@interface SwingVotesViewController ()

@end

@implementation SwingVotesViewController

@synthesize thisBill;
@synthesize LegislatorsAll;

UISwipeGestureRecognizer* gestureR;
UISwipeGestureRecognizer* gestureL;

NSMutableArray *orderedArray;
NSMutableArray *sVotes;
UIImageView *uiv;
UIButton * infoButton;

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
    
    self.navigationController.navigationItem.title=@"Swing Votes";
    
    gestureR =[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRecognizer:)];
    gestureR.direction = UISwipeGestureRecognizerDirectionRight;
    [self.tableView addGestureRecognizer:gestureR];
    
    gestureL = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRecognizerLeft:)];
    gestureL.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.tableView addGestureRecognizer:gestureL];



}
-(void)viewWillAppear:(BOOL)animated{
    //Divide up the legislators into Good,Bad, Swing
    [self refreshData];
}

- (void)refreshData{
    NSArray *theBills = [DataLoader database].savedBills;
    for (VoteTrackers * eachBill in theBills){
        if (eachBill.uniqueRowID == thisBill.uniqueRowID){
            thisBill=eachBill;
        }
    }
    orderedArray = nil;
    orderedArray = [[NSMutableArray alloc]initWithArray:thisBill.swingVotes];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"self"
                                                                     ascending:YES
                                                                    comparator:^(id obj1, id obj2) {
                                                                        return [obj1 compare:obj2 options:NSNumericSearch];
                                                                    }];
    [orderedArray sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    sVotes = [[NSMutableArray alloc]init];
    for (NSNumber * legIndex in orderedArray){

        NSUInteger newIndex=[legIndex intValue];
        if (newIndex ==711){
            //nothing.
        }
        else{
            [sVotes addObject:[LegislatorsAll objectAtIndex:newIndex]];
        }
    }
    if (sVotes.count==0){
        [self.tableView removeGestureRecognizer:gestureL];
        [self.tableView removeGestureRecognizer:gestureR];
    }
    if (sVotes.count !=0){
        [self.tableView addGestureRecognizer:gestureL];
        [self.tableView addGestureRecognizer:gestureR];
    }
    
    //Set the tab badges.
    UITabBarItem * goodTab =[self.navigationController.tabBarController.tabBar.items objectAtIndex:1];
    goodTab.badgeValue = [NSString stringWithFormat:@"%lu",(unsigned long)thisBill.goodVotes.count-1];
    
    UITabBarItem * swingTab =[self.navigationController.tabBarController.tabBar.items objectAtIndex:2];
    swingTab.badgeValue = [NSString stringWithFormat:@"%lu",(unsigned long)thisBill.swingVotes.count-1];
    
    UITabBarItem * badTab =[self.navigationController.tabBarController.tabBar.items objectAtIndex:3];
    badTab.badgeValue = [NSString stringWithFormat:@"%lu",(unsigned long)thisBill.badVotes.count-1];
    [self.tableView reloadData];
}

- (IBAction)backButton:(id)sender {
    [self.tabBarController dismissViewControllerAnimated:YES completion:NULL];
}

-(void)swipeRecognizer:(UISwipeGestureRecognizer *)gestureR {
    DataLoader *dbCrud=[[DataLoader alloc] init];
    CGPoint location = [gestureR locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];

    //Create the new bad votes array of indexes
    //Create the new swing votes array of indexes
    NSMutableArray * newBadVotes=[[NSMutableArray alloc]initWithArray:thisBill.badVotes];
    NSMutableArray * newSwingVotes=[[NSMutableArray alloc]initWithArray:orderedArray];
    [newSwingVotes removeObject:@"711"];
    [newBadVotes addObject:[newSwingVotes objectAtIndex:indexPath.row]];
    [newSwingVotes removeObjectAtIndex:indexPath.row];
    [newSwingVotes addObject:@"711"];

    //Update the swingVotes and badvotes
    [dbCrud UpdateSavedBills:thisBill.uniqueRowID :thisBill.goodVotes :newBadVotes :newSwingVotes];

    [self refreshData];
    [self.tableView reloadData];
}
-(void)swipeRecognizerLeft:(UISwipeGestureRecognizer *)gestureL {
    DataLoader *dbCrud=[[DataLoader alloc] init];
    CGPoint location = [gestureL locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    
    //Create the new bad votes array of indexes
    //Create the new swing votes array of indexes
    NSMutableArray * newGoodVotes=[[NSMutableArray alloc]initWithArray:thisBill.goodVotes];
    NSMutableArray * newSwingVotes=[[NSMutableArray alloc]initWithArray:orderedArray];
    [newSwingVotes removeObject:@"711"];
    [newGoodVotes addObject:[newSwingVotes objectAtIndex:indexPath.row]];
    [newSwingVotes removeObjectAtIndex:indexPath.row];
    [newSwingVotes addObject:@"711"];
    
    //Update the swingVotes and badvotes
    [dbCrud UpdateSavedBills:thisBill.uniqueRowID :newGoodVotes :thisBill.badVotes :newSwingVotes];
    
    [self refreshData];
    
    
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
    if (sVotes.count==0){
        return 1;
    }
    else{
        return sVotes.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"SwingCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    // Configure the cell...
    if(sVotes.count==0){
        cell.textLabel.text=@"No Votes";
        cell.detailTextLabel.text=@"Swipe someone from another tab to change that.";
        cell.userInteractionEnabled=NO;
        cell.imageView.image=nil;
        cell.contentView.backgroundColor = [UIColor whiteColor];
        [infoButton removeFromSuperview];
        
        for (UIView *subview in cell.contentView.subviews)
        {
            if ([subview isKindOfClass:[UIImageView class]])
            {
                [subview removeFromSuperview];
            }
        }
    }
    else{
        
        Legs *info=[sVotes objectAtIndex:indexPath.row];
        cell.textLabel.text=info.name;
        cell.detailTextLabel.text=[NSString stringWithFormat:@"(%@) District %@ -- %@",info.hstype, info.district, info.party];
        
        cell.detailTextLabel.textColor=[UIColor colorWithWhite:0.0 alpha:.8];
        
        cell.detailTextLabel.backgroundColor=[UIColor clearColor ];
        cell.textLabel.backgroundColor=[UIColor clearColor];
        
        //Retrieve an image
        NSString *pngName = info.imageFile;
        DataLoader *toGetStrings = [[DataLoader alloc] init];
        NSString *pngPath = [toGetStrings.GetDocumentDirectory stringByAppendingPathComponent:pngName];
        UIImage *image = [UIImage imageWithContentsOfFile: pngPath];
        
        //Add the image to the table cell
        [[cell imageView] setImage:image];
        
        [[cell imageView] setImage:image];
        if ([info.party isEqualToString:@"D"]) {
            cell.contentView.backgroundColor = [UIColor colorWithRed:0.1 green:0.3 blue:0.5 alpha:0.6];
        }
        if ([info.party isEqualToString:@"R"]) {
            cell.contentView.backgroundColor = [UIColor colorWithRed:0.8 green:0.3 blue:0.1 alpha:0.6];
        }
        if ([info.party isEqualToString:@"I"]){
            cell.contentView.backgroundColor = [UIColor colorWithRed:0.3 green:0.1 blue:0.3 alpha:0.6];
        }
        
        
        CGRect imageRect = {285,10,24,24};
        CGRect buttonRect= {280,0,40,37};
        uiv = [[UIImageView alloc] initWithFrame:imageRect];
        infoButton = [[UIButton alloc] initWithFrame:buttonRect];
        [infoButton setTitle:@" " forState:UIControlStateNormal];
        infoButton.tag = [indexPath row];
        [infoButton addTarget:self action:@selector(goToInfoPage:) forControlEvents:UIControlEventTouchUpInside];
        
        [uiv setImage:[UIImage imageNamed:[NSString stringWithFormat:@"myInfo.png"]]];
        [uiv setClipsToBounds:YES];
        
        [cell.contentView addSubview:uiv];
        [cell.contentView addSubview:infoButton];

        
        
    }
    return cell;
    
}
- (void) goToInfoPage:(id)sender{
    
    UIButton *infoButton = (UIButton *)sender;
    Legs *thisLeg = sVotes[infoButton.tag];
    
    InfoViewController * theLegInfo = [self.storyboard instantiateViewControllerWithIdentifier:@"InfoID"];
    UINavigationController *infoNav = [[UINavigationController alloc] initWithRootViewController:theLegInfo];
    UIBarButtonItem *buttonView = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:theLegInfo action:@selector(backToVotesButton:)];
    [theLegInfo setBackButton:buttonView];
    [theLegInfo setCurrentLeg:thisLeg];
    
    [self presentViewController:infoNav animated:YES completion:NULL];
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

@end
