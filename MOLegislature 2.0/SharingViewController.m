//
//  SharingViewController.m
//  CapitolBuddy
//
//  Created by Paul Rolfe on 2/9/14.
//  Copyright (c) 2014 Paul Rolfe. All rights reserved.
//

#import "SharingViewController.h"

@interface SharingViewController ()

@end

@implementation SharingViewController
@synthesize currentNote, isManager, addedUsers;

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
    self.title=@"Shared with...";
    //load current sharing users
    [self refreshSharedUsers];
    
    //Show this when scope==2 and search hasn't been clicked.
    UserObject * nilUser = [[UserObject alloc] init];
    nilUser.username = @"Click 'Search' to query all users";
    nilUser.realName = @"(search is case sensitive";
    nilUser.realOrg = @"search by name, email, or username)";
    nilArray = [NSArray arrayWithObject:nilUser];
    
    //load teams from all the PFRoles of which currentuser is member to myTeams.
    PFQuery * roleQuery = [PFRole query];
    [roleQuery whereKey:@"users" equalTo:[PFUser currentUser]];
    [roleQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error){
            
            myTeams = [[NSMutableArray alloc] init];

            for (PFRole * role in objects){
                UserObject * roleAsUser = [[UserObject alloc] init];
                roleAsUser.username = role.name;
                roleAsUser.isPFRole=TRUE;
                roleAsUser.realName=@"Type: Team";
                roleAsUser.realOrg=[NSString stringWithFormat:@"%u members",[self usersInRole:role]];
                roleAsUser.userObject=(PFRole *)role;
                [myTeams addObject: roleAsUser];
            }
            
        }
        else
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        
    }];
    if (!isManager){
        [self.tableView setTableHeaderView:nil];
    }
    
}
- (int)usersInRole:(PFRole *)role{
    [role fetchIfNeeded];
    PFQuery * usercountquery = [role.users query];
    usercountquery.cachePolicy=kPFCachePolicyNetworkElseCache;
    NSArray * roleUsers = [usercountquery findObjects];
    return (int)roleUsers.count;
}

-(void) refreshSharedUsers{
        
    currentWriters = [[NSMutableArray alloc] init];
        
    for (PFObject * user in currentNote.writeAccess){
        [user fetchInBackgroundWithBlock:^(PFObject * object, NSError *error){
            
            UserObject * localUser = [[UserObject alloc]init];
            if ([object isMemberOfClass:[PFUser class]]){
                localUser.username = object[@"username"];
                localUser.realName = object[@"realName"];
                localUser.realOrg = object[@"realOrg"];
                localUser.email = object[@"email"];
                localUser.userObject = (PFUser *)object;
                
                PFFile *userImageFile = [object objectForKey:@"imageFile"];
                localUser.imageData=[userImageFile getData];
            }
            else{
                localUser.username=object[@"name"];
                localUser.isPFRole=TRUE;
                localUser.realName=@"Type: Team";
                localUser.realOrg=[NSString stringWithFormat:@"%u members",[self usersInRole:(PFRole *)object]];
                localUser.userObject=(PFRole *)object;
            }
            
            [currentWriters addObject:localUser];
            [self.tableView reloadData];
        }];
    }
    
    currentReaders = [[NSMutableArray alloc] init];
    
    for (PFObject * user in currentNote.readAccess){
        [user fetchInBackgroundWithBlock:^(PFObject * object, NSError *error){
            
            UserObject * localUser = [[UserObject alloc]init];
            if ([object isMemberOfClass:[PFUser class]]){
                localUser.username = object[@"username"];
                localUser.realName = object[@"realName"];
                localUser.realOrg = object[@"realOrg"];
                localUser.email = object[@"email"];
                localUser.userObject = (PFUser *)object;
                
                PFFile *userImageFile = [object objectForKey:@"imageFile"];
                localUser.imageData=[userImageFile getData];
            }
            else{
                localUser.username=object[@"name"];
                localUser.isPFRole=TRUE;
                localUser.realName=@"Type: Team";
                localUser.realOrg=[NSString stringWithFormat:@"%u members",[self usersInRole:(PFRole *)object]];
                localUser.userObject=(PFRole *)object;
            }
            
            [currentReaders addObject:localUser];
            [self.tableView reloadData];
        }];
    }
    
    
    //load recent contacts from current user [@"buddies"] pf relation? to recentUsers.
    recentUsers = [[NSMutableArray alloc]init];
    
    [[PFUser currentUser] fetchInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        
        if(!error){
            NSArray * buddies = object[@"buddies"];
            
            for (PFUser * user in buddies){
                [user fetchInBackgroundWithBlock:^(PFObject * object, NSError *error){
                    
                    if (!error){
                        UserObject * localUser = [[UserObject alloc]init];
                        localUser.username = object[@"username"];
                        localUser.realName = object[@"realName"];
                        localUser.realOrg = object[@"realOrg"];
                        localUser.email = object[@"email"];
                        localUser.userObject = (PFUser *)object;
                        
                        PFFile *userImageFile = [object objectForKey:@"imageFile"];
                        localUser.imageData=[userImageFile getData];
                        
                        [recentUsers addObject:localUser];
                    }
                    else
                        NSLog(@"Error: %@ %@", error, [error userInfo]);
                }];
            }
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

#pragma mark - Table view data source
-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString{
    
    NSInteger scope = controller.searchBar.selectedScopeButtonIndex;
    [self filterContentForSearchText:searchString inScope:scope];
    return YES;
    
}
-(BOOL) searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption{
    switch (searchOption) {
        case 0://recent shares
            controller.searchBar.placeholder=@"Search by username, email, or real name";
            [self filterContentForSearchText:controller.searchBar.text inScope:searchOption];
            break;
        case 1://My Teams
            controller.searchBar.placeholder=@"Search by team name";
            [self filterContentForSearchText:controller.searchBar.text inScope:searchOption];
            break;
        case 2://All Users
            controller.searchBar.placeholder=@"Search by username, email, or real name";
            [self filterContentForSearchText:controller.searchBar.text inScope:searchOption];
            break;
        default:
            break;
    }
    return YES;
}
- (void)filterContentForSearchText:(NSString*)searchText inScope:(NSInteger)scope{
    
    NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"(username contains[cd] %@) OR (email contains[cd] %@) OR (realName contains[cd] %@)",searchText, searchText, searchText];
    
    if ([searchText isEqualToString:@""]){
        [(UITableView *)[self.parentViewController.view viewWithTag:7] reloadData];
        [(UITableView *)[self.parentViewController.view viewWithTag:7] setHidden:NO];
    }
    else{
        [(UITableView *)[self.parentViewController.view viewWithTag:7] setHidden:YES];

        switch (scope) {
            case 0://buddies
                searchResults = [recentUsers filteredArrayUsingPredicate:resultPredicate];
                break;
            case 1://my teams
                searchResults = [myTeams filteredArrayUsingPredicate:resultPredicate];
                break;
            case 2://all users
                searchResults=nilArray;
            default:
                break;
        }
    }
}
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    
    //do the search through all users.
    if (searchBar.selectedScopeButtonIndex==2){
        
        //search for the user.
        PFQuery *emailquery = [PFUser query];
        [emailquery whereKey:@"email" equalTo:searchBar.text];
        
        PFQuery *namequery = [PFUser query];
        [namequery whereKey:@"username" equalTo:searchBar.text];
        
        PFQuery *realnamequery = [PFUser query];
        [realnamequery whereKey:@"realName" equalTo:searchBar.text];
        
        PFQuery * query = [PFQuery orQueryWithSubqueries:@[emailquery,namequery,realnamequery]];
        
        //Query all users for the search string.
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                NSLog(@"%lu results",(unsigned long)objects.count);
                
                NSMutableArray * userResults = [[NSMutableArray alloc] init];
                
                for (PFUser * user in objects){
                    [user fetchInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                        UserObject * localUser = [[UserObject alloc]init];
                        localUser.username = user.username;
                        localUser.realName = user[@"realName"];
                        localUser.realOrg = user[@"realOrg"];
                        localUser.email = user.email;
                        localUser.userObject = (PFUser *)user;
                        
                        PFFile *userImageFile = [user objectForKey:@"imageFile"];
                        localUser.imageData=[userImageFile getData];
                        
                        [userResults addObject:localUser];
                        searchResults = userResults;
                        [self.searchDisplayController.searchResultsTableView reloadData];
                    }];
                    

                }
                
            }
            if (objects.count==0){
                UserObject * inviteLink = [[UserObject alloc] init];
                inviteLink.username = [NSString stringWithFormat:@"Invite %@ to CapitolBuddy!",searchBar.text];
                inviteLink.realName = @"Click to send email invitation";
                inviteLink.realOrg = @"then share later.";
                inviteLink.email = @"Invite";
                inviteLink.userObject = nil;
                
                searchResults=[[NSArray alloc]initWithObjects:inviteLink, nil];
                
                [self.searchDisplayController.searchResultsTableView reloadData];

            }
            if (error){
                // Log details of the failure
                NSLog(@"Error: %@ %@", error, [error userInfo]);
                searchResults=nil;
            }
        }];
    }
}
-(void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar{
    NSLog(@"started editing");
    //[[self.parentViewController.view viewWithTag:7] removeFromSuperview];
    [self showInitialResults];
}
-(void)searchBarTextDidEndEditing:(UISearchBar *)searchBar{
    [[self.parentViewController.view viewWithTag:7] removeFromSuperview];
    NSLog(@"ended editing");
}
-(void)showInitialResults{
    CGRect tvframe = CGRectMake(0, 139, self.parentViewController.view.frame.size.width,self.parentViewController.view.frame.size.height);    UITableView * initialTable = [[UITableView alloc] initWithFrame:tvframe style:UITableViewStylePlain];
    initialTable.tag=7;
    initialTable.delegate=self;
    initialTable.dataSource=self;
    [self.parentViewController.view addSubview:initialTable];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    if (tableView == self.searchDisplayController.searchResultsTableView || tableView.tag==7) {
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
    if(tableView.tag==7){
        NSInteger scope = self.searchDisplayController.searchBar.selectedScopeButtonIndex;
        switch (scope) {
            case 0:
                return recentUsers.count;
                break;
            case 1:
                return myTeams.count;
                break;
            case 2:
                return 1;
                break;
            default:
                return 0;
        }
    }
    else{
        // Return the number of rows in the section.
        if (section==0)
            return currentWriters.count;
        if (section==1)
            return currentReaders.count;
        else
            return 0;
    }
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    
    if (tableView == self.searchDisplayController.searchResultsTableView || tableView.tag==7) {
        return @"Results";
    }
    else{
        if (section==0)
            return @"Read & Write";
        if (section==1)
            return @"Read Only";
        else
            return @"Error";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ShareCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    // Configure the cell...
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        UserObject * user = [searchResults objectAtIndex:indexPath.row];
        [[cell viewWithTag:555] removeFromSuperview];
        if ([user.email isEqualToString:@"Invite"]){
            UIButton * inviteButton = [[UIButton alloc] initWithFrame:cell.textLabel.frame];
            inviteButton.tag=555;
            [inviteButton setTitle:user.username forState:UIControlStateNormal];
            [inviteButton addTarget:self action:@selector(showInviteAlert) forControlEvents:UIControlEventTouchUpInside];
            inviteButton.backgroundColor=[UIColor colorWithRed:0 green:.3 blue:.6 alpha:.7];
            [cell.contentView addSubview:inviteButton];
            cell.detailTextLabel.text=[NSString stringWithFormat:@"%@, %@",user.realName, user.realOrg];
            cell.textLabel.text=@" ";
            return cell;
        }
        else{
            cell.textLabel.text=user.username;
            cell.detailTextLabel.text=[NSString stringWithFormat:@"%@, %@",user.realName, user.realOrg];
            cell.imageView.image = [UIImage imageWithData:user.imageData];
            
            cell.textLabel.backgroundColor = [UIColor clearColor];
            cell.detailTextLabel.backgroundColor = [UIColor clearColor];
            
            if (user.isPFRole){
                cell.contentView.backgroundColor=[UIColor colorWithRed:1 green:1 blue:.5 alpha:1];
            }
            else{
                cell.contentView.backgroundColor=[UIColor whiteColor];
            }
            return cell;
        }
        
    }
    else if (tableView.tag==7){
        NSInteger scope = self.searchDisplayController.searchBar.selectedScopeButtonIndex;
        UserObject * user = [[UserObject alloc] init];
        switch (scope) {
            case 0:
                user = [recentUsers objectAtIndex:indexPath.row];
                break;
            case 1:
                user = [myTeams objectAtIndex:indexPath.row];
                break;
            case 2:
                user=[nilArray objectAtIndex:indexPath.row];
                break;
        }
        cell.textLabel.text=user.username;
        cell.detailTextLabel.text=[NSString stringWithFormat:@"%@, %@",user.realName, user.realOrg];
        cell.imageView.image = [UIImage imageWithData:user.imageData];
        
        cell.textLabel.backgroundColor = [UIColor clearColor];
        cell.detailTextLabel.backgroundColor = [UIColor clearColor];
        
        if (user.isPFRole){
            cell.contentView.backgroundColor=[UIColor colorWithRed:1 green:1 blue:.5 alpha:1];
        }
        else{
            cell.contentView.backgroundColor=[UIColor whiteColor];
        }
    }
    else{
        if (indexPath.section==0){
            UserObject * user = [currentWriters objectAtIndex:indexPath.row];
            [currentNote.owner fetchIfNeeded];

            cell.textLabel.text=user.username;
            cell.detailTextLabel.text=[NSString stringWithFormat:@"%@, %@",user.realName, user.realOrg];
            cell.imageView.image = [UIImage imageWithData:user.imageData];
            
            cell.textLabel.backgroundColor = [UIColor clearColor];
            cell.detailTextLabel.backgroundColor = [UIColor clearColor];
            
            if (user.isPFRole){
                cell.contentView.backgroundColor=[UIColor colorWithRed:1 green:1 blue:.5 alpha:1];
            }
            else if([user.username isEqualToString:currentNote.owner.username]){
                cell.contentView.backgroundColor=[UIColor colorWithRed:0.1 green:0.3 blue:0.5 alpha:0.6];
            }
            else{
                cell.contentView.backgroundColor=[UIColor whiteColor];
            }
            
        }
            
        if (indexPath.section==1){
            
            UserObject * user = [currentReaders objectAtIndex:indexPath.row];
            cell.textLabel.text=user.username;
            cell.detailTextLabel.text=[NSString stringWithFormat:@"%@, %@",user.realName, user.realOrg];
            cell.imageView.image = [UIImage imageWithData:user.imageData];
            
            cell.textLabel.backgroundColor = [UIColor clearColor];
            cell.detailTextLabel.backgroundColor = [UIColor clearColor];
            
            if (user.isPFRole){
                cell.contentView.backgroundColor=[UIColor colorWithRed:1 green:1 blue:.5 alpha:1];
            }
            else{
                cell.contentView.backgroundColor=[UIColor whiteColor];
            }
        }
    }
    return cell;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView != self.searchDisplayController.searchResultsTableView && isManager && tableView.tag!=7){
        
        PFUser * userID;
        
        if (indexPath.section==0){
            UserObject * user =[currentWriters objectAtIndex:indexPath.row];
            userID = (PFUser *)user.userObject;
            if (![currentNote.owner.objectId isEqualToString: userID.objectId]) {
                return YES;
            }
            else {
                return NO;
            }
        }
        else
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
            //let them delete it as long as it's not their access and if they have write access.
            UserObject * deleteThis = [currentWriters objectAtIndex:indexPath.row];

            [currentNote.writeAccess removeObject:deleteThis.userObject];
            [currentWriters removeObjectAtIndex:indexPath.row];
            [currentNote.sharingSettings setWriteAccess:NO forUser:(PFUser *)deleteThis.userObject];
            [currentNote.sharingSettings setReadAccess:NO forUser:(PFUser *)deleteThis.userObject];
            
            [addedUsers removeObject:deleteThis.userObject.objectId];

            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];

        }
        if (indexPath.section==1){
            UserObject * deleteThis = [currentReaders objectAtIndex:indexPath.row];
            
            [currentNote.readAccess removeObject:deleteThis.userObject];
            [currentReaders removeObjectAtIndex:indexPath.row];
            
            [currentNote.sharingSettings setReadAccess:NO forUser:(PFUser *)deleteThis.userObject];

            [addedUsers removeObject:deleteThis.userObject.objectId];

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
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (tableView==self.searchDisplayController.searchResultsTableView || tableView.tag==7){
        
        
        if (tableView.tag==7){
            NSInteger scope = self.searchDisplayController.searchBar.selectedScopeButtonIndex;
            switch (scope) {
                case 0:
                    selectedUserObject = [recentUsers objectAtIndex:indexPath.row];
                    break;
                case 1:
                    selectedUserObject = [myTeams objectAtIndex:indexPath.row];
                    break;
                case 2:
                    selectedUserObject=[nilArray objectAtIndex:indexPath.row];
            }
        }
        else
            selectedUserObject = [searchResults objectAtIndex:indexPath.row];

        
        //if it's a team do this.
        if (selectedUserObject.isPFRole){
            selectedRole = (PFRole *)selectedUserObject.userObject;
            [self askWhichPermissions];
        }
        //send invite if the result is an invite object
        else if ([selectedUserObject.email isEqualToString:@"Invite"]){
            [self showInviteAlert];
        }
        //do nothing if the object is the nil array.
        else if([selectedUserObject.username isEqualToString:@"Click 'Search' to query all users"]){
        
        }
        // if it's a person do this.
        else{
            selectedUser = (PFUser *)selectedUserObject.userObject;
            [self askWhichPermissions];
        }
    }
}
-(void)showInviteAlert{
    UIAlertView * inviteAlert = [[UIAlertView alloc]initWithTitle:@"Invite via Email" message:@"Enter the email address to send the invite." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Send", nil];
    inviteAlert.alertViewStyle=UIAlertViewStylePlainTextInput;
    answerField = [inviteAlert textFieldAtIndex:0];
    answerField.keyboardType = UIKeyboardTypeEmailAddress;
    answerField.text = self.searchDisplayController.searchBar.text;
    answerField.autocapitalizationType=UITextAutocapitalizationTypeNone;
    answerField.clearButtonMode=UITextFieldViewModeAlways;
    inviteAlert.tag = 700;
    [inviteAlert show];
}
-(void)askWhichPermissions{
    UIAlertView * readwrite = [[UIAlertView alloc] initWithTitle:@"Permissions" message:@"Would you like to grant write access or read only?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Write",@"Read Only", nil];
    [readwrite show];
}

//method in the aim of keeping duplicate permissions.
-(BOOL) doesArray:(NSArray *)array containUser:(UserObject*)user{
    
    for (UserObject * eachUser in array){
        if (![eachUser.username isEqualToString:selectedUserObject.username]){
        
        }
        else{
            return YES;
        }
    }
    
    return NO;
}

-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if (alertView.tag==700){
        if (buttonIndex == 1){//send
            //send to some parse function that checks the email and sends the invite.
            [PFCloud callFunctionInBackground:@"inviteEmail"
                               withParameters:@{@"sender" : [PFUser currentUser].username,
                                                @"sendTo" : answerField.text}
                                        block:^(NSString *result, NSError *error) {
                                            if (!error) {
                                                NSLog(@"Email sent!");
                                                [self popupImage];
                                            }
                                            else{
                                                UIAlertView * noEmailSent = [[UIAlertView alloc] initWithTitle:@"Error" message:[error userInfo][@"error"] delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
                                                [noEmailSent show];
                                            }
                                        }];

        }
    }
    
    else{
        if (buttonIndex == 1){//write
            //only save it if the user/role is note already included.
            if (![self doesArray:currentWriters containUser:selectedUserObject]){
                
                //if it's a role, add the role
                if (selectedUserObject.isPFRole){
                    [currentNote.writeAccess addObject:selectedRole];
                    [currentNote.sharingSettings setWriteAccess:YES forRole:selectedRole];
                    [currentNote.sharingSettings setReadAccess:YES forRole:selectedRole];
                    [self refreshSharedUsers];
                    [self.searchDisplayController setActive:NO animated:YES];
                }
                //if it's a user, add the user.
                else{
                    [currentNote.writeAccess addObject:selectedUser];
                    [currentNote.sharingSettings setWriteAccess:YES forUser:selectedUser];
                    [currentNote.sharingSettings setReadAccess:YES forUser:selectedUser];
                    
                    [addedUsers addObject:selectedUser.objectId];
                    [self addBuddy];
                    [self.searchDisplayController setActive:NO animated:YES];
                }
            }
        }
        if (buttonIndex == 2){//read only
            
            //only save it if the user/role is not already included.
            if (![self doesArray:currentReaders containUser:selectedUserObject]){
                
                //if it's a role, add the role
                if (selectedUserObject.isPFRole){
                    if (currentNote.readAccess==nil){
                        currentNote.readAccess = [[NSMutableArray alloc]initWithObjects:selectedRole, nil];
                    }
                    else{
                        [currentNote.readAccess addObject:selectedRole];
                    }
                    [currentNote.sharingSettings setReadAccess:YES forRole:selectedRole];
                    [self refreshSharedUsers];
                    [self.searchDisplayController setActive:NO animated:YES];
                }
                //if it's a user, add the user.
                else{
                    if (currentNote.readAccess==nil){
                        currentNote.readAccess = [[NSMutableArray alloc]initWithObjects:selectedUser, nil];
                    }
                    else{
                        [currentNote.readAccess addObject:selectedUser];
                    }
                    [currentNote.sharingSettings setReadAccess:YES forUser:selectedUser];
                    [addedUsers addObject:selectedUser.objectId];
                    [self addBuddy];
                    [self.searchDisplayController setActive:NO animated:YES];
                }
            }
        }
    }

}
- (void) addBuddy{
    //Add them to current user's buddy list.
    PFQuery *queryUser = [PFQuery queryWithClassName:@"_User"];
    
    [queryUser getObjectInBackgroundWithId:[PFUser currentUser].objectId block:^(PFObject *object, NSError *error) {
        
        [object addUniqueObject:selectedUser forKey:@"buddies"];
        
        [object saveInBackgroundWithTarget:self selector:@selector(refreshSharedUsers)];
        
    }];
    
}

#pragma mark - Navigation
 - (IBAction)backToNotesButton:(id)sender {
     /*
//change the note ACL setting to reflect the new sharing.
     
     [newACL setPublicWriteAccess:YES];
     
     for (PFObject *user in currentNote.writeAccess) {
         if ([user isMemberOfClass:[PFRole class]]){
             [newACL setReadAccess:YES forRole:(PFRole *)user];
             [newACL setWriteAccess:YES forRole:(PFRole *)user];
         }
         else{
             [newACL setWriteAccess:YES forUser:(PFUser *)user];
             [newACL setReadAccess:YES forUser:(PFUser *)user];
         }
     }
     for (PFObject *user in currentNote.readAccess){
         if ([user isMemberOfClass:[PFRole class]]){
             [newACL setReadAccess:YES forRole:(PFRole *)user];
         }
         else{
             [newACL setReadAccess:YES forUser:(PFUser *)user];
         }
     }
     currentNote.sharingSettings=newACL;
     
      */
     [self dismissViewControllerAnimated:YES completion:NULL];

}
-(void)popupImage
{
    if (check==nil){
        check = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"check.png"]];
        check.frame = CGRectMake(self.view.frame.size.width/2-50, self.view.frame.size.height/2-50, 100, 100);
        check.tintColor=[UIColor grayColor];
        check.backgroundColor=[UIColor lightGrayColor];
        [self.view addSubview:check];
    }
    
    check.hidden = NO;
    check.alpha = 0.8f;
    // Then fades it away after 2 seconds (the cross-fade animation will take 0.5s)
    [UIView animateWithDuration:0.5 delay:2.0 options:0 animations:^{
        // Animate the alpha value of your imageView from 1.0 to 0.0 here
        check.alpha = 0.0f;
    } completion:^(BOOL finished) {
        // Once the animation is completed and the alpha has gone to 0.0, hide the view for good
        check.hidden = YES;
    }];
}

@end
