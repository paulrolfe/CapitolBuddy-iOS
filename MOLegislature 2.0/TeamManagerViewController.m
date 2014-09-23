//
//  TeamManagerViewController.m
//  CapitolBuddy
//
//  Created by Paul Rolfe on 2/13/14.
//  Copyright (c) 2014 Paul Rolfe. All rights reserved.
//

#import "TeamManagerViewController.h"

@interface TeamManagerViewController ()

@end

@implementation TeamManagerViewController

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
    self.title = @"My Teams";
    
    if ([[PFUser currentUser] isAuthenticated] && ![PFAnonymousUtils isLinkedWithUser:[PFUser currentUser]]){
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(createTeamAction:)];
        loggedIn=YES;
    }
    else{
        //add something that says to log in.
        UILabel * help = [[UILabel alloc] initWithFrame:CGRectMake(20, self.tableView.tableFooterView.frame.origin.y+100, 280, 200)];
        help.text=@"Log in to take advantage of teams.\n\n(We can't make a team for you if we don't know who you are...)";
        help.numberOfLines=0;
        help.lineBreakMode=NSLineBreakByWordWrapping;
        help.tag=446;
        [self.view addSubview:help];
        loggedIn=NO;
    }
    
    self.navigationItem.prompt = @"Share easier with teams.";
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
- (void) viewWillAppear:(BOOL)animated{
    if ([[PFUser currentUser] isAuthenticated] && ![PFAnonymousUtils isLinkedWithUser:[PFUser currentUser]]){
        [self refreshRoles];
    }
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        if (UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation])){
            self.navigationItem.leftBarButtonItem=nil;
        }
    }
}

-(void) refreshRoles{
    PFQuery * roleQuery = [PFRole query];
    [roleQuery whereKey:@"users" equalTo:[PFUser currentUser]];
    [roleQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error){
            
            PFUser * user = [PFUser currentUser];
            managedTeams = [[NSMutableArray alloc]init];
            otherTeams = [[NSMutableArray alloc] init];
            managedTeamCount = [[NSMutableArray alloc] init];
            otherTeamCount = [[NSMutableArray alloc] init];
            
            for (PFRole * role in objects){
                [role fetchIfNeeded];
                
                if ([role.ACL getWriteAccessForUser:user]){
                    [managedTeams addObject:role];
                    [managedTeamCount addObject:[self usersInRole:role]];
                }
                else{
                    [otherTeams addObject:role];
                    [otherTeamCount addObject:[self usersInRole:role]];
                }
            }
            [self.tableView reloadData];
            
        }
        else
            NSLog(@"Error: %@ %@", error, [error userInfo]);
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString *)usersInRole:(PFRole *)role{
    [role fetchIfNeeded];
    PFQuery * usercountquery = [role.users query];
    NSArray * roleUsers = [usercountquery findObjects];
    return [NSString stringWithFormat:@"%lu",(unsigned long)roleUsers.count];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}
-(void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section==0){
        return managedTeams.count;
    }
    if (section ==1){
        return otherTeams.count;
    }
    else{
        return 0;
    }
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    
    if (section==0){
        return @"Teams Managed by Me";
    }
    if (section ==1){
        return @"My Other Teams";
    }
    else{
        return @"error";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"TeamCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    if (indexPath.section==0){
        PFRole * role = [managedTeams objectAtIndex:indexPath.row];
        cell.textLabel.text=role.name;
        cell.detailTextLabel.text=[NSString stringWithFormat:@"%@ members",[managedTeamCount objectAtIndex:indexPath.row]];
        cell.backgroundColor=[UIColor colorWithRed:1 green:1 blue:.5 alpha:1];

    }
    if (indexPath.section==1){
        PFRole * role = [otherTeams objectAtIndex:indexPath.row];
        cell.textLabel.text=role.name;
        cell.detailTextLabel.text=[NSString stringWithFormat:@"%@ members",[otherTeamCount objectAtIndex:indexPath.row]];
        cell.backgroundColor=[UIColor colorWithRed:1 green:1 blue:.5 alpha:1];

    }
    return cell;
}
-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    if (section==1 && loggedIn){
        if (footerView==nil){
            footerView = [[UIView alloc] init];
            
            //create the button
            UILabel * help = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2-140, 3, 280, 200)];
            help.text=@"Tap the '+' to create a team.\n\nThen add users by tapping a team that you manage, and searching for other CapitolBuddy users.\n\nNow you can quickly share news privately with your whole team with a tap.";
            help.numberOfLines=0;
            help.lineBreakMode=NSLineBreakByWordWrapping;
            help.tag=446;
            [footerView addSubview:help];
            //return the view for the footer
        }
        return footerView;
    }
    else
        return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    if (section==1)
        return 200;
    else
        return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{

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
        if (indexPath.section==0){
            //pick the role/team to delete
            PFRole * roleToDelete = [managedTeams objectAtIndex:indexPath.row];
            
            //delete the role from the notes where it is associated.
            PFQuery * writeQuery = [PFQuery queryWithClassName:@"Notes"];
            [writeQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                NSLog(@"%lu notes found",(unsigned long)objects.count);
                
                for (PFObject * note in objects){
                    //remove from the array
                    [note fetchIfNeeded];
                    [note removeObject:roleToDelete forKey:@"writeAccess"];
                    [note removeObject:roleToDelete forKey:@"readAccess"];
                    [note saveInBackground];
                }

            }];
            
            //delete the role from the server
            PFQuery * roleQuery = [PFRole query];
            [roleQuery getObjectInBackgroundWithId:roleToDelete.objectId block:^(PFObject *object, NSError *error){
                if (!error){
                    [object deleteInBackground];
                }
                else
                    NSLog(@"Error: %@ %@", error, [error userInfo]);
                
            }];
            
            //remove the role from the view.
            [managedTeams removeObjectAtIndex:indexPath.row];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];

        }
        if (indexPath.section==1){
            //remove the user from the PFRole's user and save the PFRole.
            PFRole * roleToDelete = [otherTeams objectAtIndex:indexPath.row];
            PFQuery * roleQuery = [PFRole query];
            [roleQuery getObjectInBackgroundWithId:roleToDelete.objectId block:^(PFObject *object, NSError *error){
                if (!error){
                    [object[@"users"] removeObject:[PFUser currentUser]];
                    [object saveInBackground];
                    

                }
                else
                    NSLog(@"Error: %@ %@", error, [error userInfo]);
                
            }];
            
            //remove the role from the view.
            [otherTeams removeObjectAtIndex:indexPath.row];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
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


#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    AddUsersViewController * auvc = [segue destinationViewController];
    
    if (indexPath.section==0){
        //show the users and let them be added.
        //bring up the sharing view controller.
        roleToEdit = (PFRole *)[managedTeams objectAtIndex:indexPath.row];
        [auvc setIsManager:YES];
        
    }
    if (indexPath.section==1){
        //show the users in it, but don't let it be editable.
        roleToEdit = (PFRole *)[otherTeams objectAtIndex:indexPath.row];
        [auvc setIsManager:NO];
    }
    // Get the new view controller using [segue destinationViewController].

    [auvc setCurrentRole:roleToEdit];
}


-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex==1){//they clicked Create.
        
        NSString *myRegex = @"[A-Z0-9a-z_ ]*";
        NSPredicate *myTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", myRegex];
        BOOL valid = [myTest evaluateWithObject:answerField.text];
        
        if (valid && ![answerField.text isEqualToString: @""]){
            PFACL * roleACL = [PFACL ACLWithUser:[PFUser currentUser]];
            [roleACL setPublicReadAccess:YES];
            [roleACL setPublicWriteAccess:YES];
            
            PFRole * newRole = [PFRole roleWithName:answerField.text acl:roleACL];
            [newRole.users addObject:[PFUser currentUser]];
            [newRole saveInBackgroundWithTarget:self selector:@selector(refreshRoles)];

        }
        else{
            UIAlertView * newTeamAlert = [[UIAlertView alloc]initWithTitle:@"Name Your Team" message:@"You had some illegal characters. (Please use only letters, numbers, and spaces)\n\nGive it another shot!" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Create", nil];
            newTeamAlert.alertViewStyle=UIAlertViewStylePlainTextInput;
            answerField = [newTeamAlert textFieldAtIndex:0];
            answerField.keyboardType = UIKeyboardTypeDefault;
            answerField.placeholder = @"your new team name";
            answerField.autocapitalizationType=UITextAutocapitalizationTypeWords;
            [newTeamAlert show];
        }
    }
}

- (IBAction)createTeamAction:(id)sender {
    UIAlertView * newTeamAlert = [[UIAlertView alloc]initWithTitle:@"Name Your Team" message:@"Name your team now and add members later.\n\n(Please use only letters, numbers, and spaces)" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Create", nil];
    newTeamAlert.alertViewStyle=UIAlertViewStylePlainTextInput;
    answerField = [newTeamAlert textFieldAtIndex:0];
    answerField.keyboardType = UIKeyboardTypeDefault;
    answerField.placeholder = @"your new team name";
    answerField.autocapitalizationType=UITextAutocapitalizationTypeWords;
    [newTeamAlert show];
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
            [self.navigationItem setLeftBarButtonItem: navigationPaneBarButtonItem
                                             animated:NO];
        else
            [self.navigationItem setLeftBarButtonItem:nil
                                             animated:NO];
    }
    
    _navigationPaneBarButtonItem = navigationPaneBarButtonItem;
    
    
}



@end
