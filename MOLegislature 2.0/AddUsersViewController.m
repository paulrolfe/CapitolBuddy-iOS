//
//  AddUsersViewController.m
//  CapitolBuddy
//
//  Created by Paul Rolfe on 2/13/14.
//  Copyright (c) 2014 Paul Rolfe. All rights reserved.
//

#import "AddUsersViewController.h"

@interface AddUsersViewController ()

@end

@implementation AddUsersViewController

@synthesize currentRole,saveButtonView,isManager;

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
    self.title=[NSString stringWithFormat:@"%@",currentRole.name];
    
    [currentRole fetchIfNeededInBackgroundWithTarget:self selector:@selector(refreshMembers)];

    if (!isManager){
        [self.tableView setTableHeaderView:nil];
        self.navigationItem.prompt = @"View Team Members";

    }
    else{
        self.navigationItem.prompt = @"Edit Team Members";

        saveButtonView = [[UIBarButtonItem alloc] initWithTitle:@"Saved" style:UIBarButtonItemStylePlain target:self action:@selector(savePFRole:)];
        self.navigationItem.rightBarButtonItem=saveButtonView;
        saveButtonView.enabled=NO;
        
        UserObject * nilUser = [[UserObject alloc] init];
        nilUser.username = @"Click 'Search' to query all users";
        nilUser.realName = @"(search is case sensitive";
        nilUser.realOrg = @"search by name, email, or username)";
        nilArray = [NSArray arrayWithObject:nilUser];
        
        [self refreshBuddies];
    }

}
-(void) refreshMembers{
    
    currentMembers = [[NSMutableArray alloc] init];
    currentManagers = [[NSMutableArray alloc]init];
    
    PFRelation *userRelation = [currentRole relationforKey:@"users"];
    PFQuery *userRelationQuery = [userRelation query];
    [userRelationQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (objects.count > 0 && !error) {
            NSLog(@"Found some users: %lu!", (unsigned long)objects.count);
            //Take this array and make it into an array of users
            
            for (PFUser * user in objects){
                [user fetchIfNeeded];
                
                [currentMembers addObject:user];
                
                if ([currentRole.ACL getWriteAccessForUser:user]){
                    [currentManagers addObject:user];
                }
                [self.tableView reloadData];
            }
            
        } else {
            NSLog(@"No users found");
        }
    }];
}
-(void) refreshBuddies{

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


- (void)filterContentForSearchText:(NSString*)searchText inScope:(NSInteger)scope
{
    
    NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"(username contains[cd] %@) OR (email contains[cd] %@) OR (realName contains[cd] %@)",searchText, searchText, searchText];
    
    if ([searchText isEqualToString:@""]){
        [(UITableView *)[self.parentViewController.view viewWithTag:7] reloadData];
        [(UITableView *)[self.parentViewController.view viewWithTag:7] setHidden:NO];
    }
    else{
        [(UITableView *)[self.parentViewController.view viewWithTag:7] setHidden:YES];
        
        switch (scope) {
            case 0:
                searchResults = [recentUsers filteredArrayUsingPredicate:resultPredicate];
                break;
            case 1:
                searchResults=nilArray;
                break;
            default:
                break;
        }
    
    }
}

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString{
    
    NSInteger scope = controller.searchBar.selectedScopeButtonIndex;
    [self filterContentForSearchText:searchString inScope:scope];
    return YES;
    
}
-(BOOL) searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption{
    
    [self filterContentForSearchText:controller.searchBar.text inScope:searchOption];
    return YES;
}
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    
    //do the search through all users.
    if (searchBar.selectedScopeButtonIndex==1){
        
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
    [self showInitialResults];
}
-(void)searchBarTextDidEndEditing:(UISearchBar *)searchBar{
    [[self.parentViewController.view viewWithTag:7] removeFromSuperview];
    NSLog(@"ended editing");
}
-(void)showInitialResults{
    CGRect tvframe = CGRectMake(0, 139, self.parentViewController.view.frame.size.width,self.parentViewController.view.frame.size.height);
    UITableView * initialTable = [[UITableView alloc] initWithFrame:tvframe style:UITableViewStylePlain];
    initialTable.tag=7;
    initialTable.delegate=self;
    initialTable.dataSource=self;
    [self.parentViewController.view addSubview:initialTable];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
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
                return 1;
                break;
            default:
                return 0;
        }
    }
    else{
        // Return the number of rows in the section.
        return currentMembers.count;
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
        PFUser * user = [currentMembers objectAtIndex:indexPath.row];
        [user fetchIfNeeded];
        
        cell.textLabel.text=user.username;
        cell.detailTextLabel.text=[NSString stringWithFormat:@"%@, %@",user[@"realName"], user[@"realOrg"]];
        
        PFFile *userImageFile = [user objectForKey:@"imageFile"];
        NSData * imageData=[userImageFile getData];
        cell.imageView.image = [UIImage imageWithData:imageData];
        
        cell.textLabel.backgroundColor = [UIColor clearColor];
        cell.detailTextLabel.backgroundColor = [UIColor clearColor];
        
        if ([currentManagers containsObject:user]){
            cell.contentView.backgroundColor=[UIColor colorWithRed:0.1 green:0.3 blue:0.5 alpha:0.6];
        }
        else{
            cell.contentView.backgroundColor=[UIColor whiteColor];
        }
    }
    return cell;
}
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    //let them delete it as long as they're a manager, only in regular tableview.

    if (tableView != self.searchDisplayController.searchResultsTableView && tableView.tag!=7){
    
        if (isManager)
            return YES;
        else
            return NO;
    }
    else
        return NO;
    
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        self.navigationItem.rightBarButtonItem.title=@"Save";
        self.navigationItem.rightBarButtonItem.enabled=YES;
        
        PFUser * userToRemove = (PFUser *)[currentMembers objectAtIndex:indexPath.row];
        
        //allow them to delete themselves only if there is another manager.
        if ([currentManagers containsObject:userToRemove]){
            if (currentManagers.count>1){
                [currentManagers removeObject:userToRemove];
                [currentMembers removeObjectAtIndex:indexPath.row];
                [currentRole.users removeObject:userToRemove];
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];

            }
            else{
                UIAlertView * readwrite = [[UIAlertView alloc] initWithTitle:@"Needs a manager" message:@"You can only remove a manager if there is at least one other manager declared." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
                [readwrite show];
            }
        }
        else{
            [currentRole.users removeObject:userToRemove];
            [currentMembers removeObjectAtIndex:indexPath.row];
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
    
    //the tableviews for adding users
    if (tableView==self.searchDisplayController.searchResultsTableView || tableView.tag==7){
        
        if (tableView.tag==7){
            NSInteger scope = self.searchDisplayController.searchBar.selectedScopeButtonIndex;
            switch (scope) {
                case 0:
                    selectedUserObject = [recentUsers objectAtIndex:indexPath.row];
                    break;
                case 2:
                    selectedUserObject=[nilArray objectAtIndex:indexPath.row];
                    break;
            }
        }
        else
            selectedUserObject = [searchResults objectAtIndex:indexPath.row];
        
        selectedUser = (PFUser *)selectedUserObject.userObject;
        
        //send invite if the result is an invite object
        if ([selectedUserObject.email isEqualToString:@"Invite"]){
            
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
        //do nothing if the object is the nil array.
        else if([selectedUserObject.username isEqualToString:@"Click 'Search' to query all users"]){
            
        }
        else{
            self.navigationItem.rightBarButtonItem.title=@"Save";
            self.navigationItem.rightBarButtonItem.enabled=YES;
            
            [currentMembers addObject:selectedUser];
            [currentRole.users addObject:selectedUser];
            [self addBuddy];
            [self.searchDisplayController setActive:NO animated:YES];
            [self.tableView reloadData];
        }
    }
    //the tableview for making managers
    else{
        selectedUser = [currentMembers objectAtIndex:indexPath.row];

        if (![currentManagers containsObject:selectedUser] && isManager){
            UIAlertView * readwrite = [[UIAlertView alloc] initWithTitle:@"Permissions" message:@"Would you like to make this user a manager of this team?" delegate:self cancelButtonTitle:nil otherButtonTitles:@"Make manager",@"Cancel", nil];
            readwrite.tag=115;
            [readwrite show];
        }
        else if ([currentManagers containsObject:selectedUser] && isManager){
            UIAlertView * readwrite = [[UIAlertView alloc] initWithTitle:@"Permissions" message:@"Would you like to remove this user's status as manager?" delegate:self cancelButtonTitle:nil otherButtonTitles:@"Remove manager",@"Cancel", nil];
            readwrite.tag=116;
            [readwrite show];
            
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

-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if (alertView.tag==115){
        if (buttonIndex == 0){//Make Manager
            self.navigationItem.rightBarButtonItem.title=@"Save";
            self.navigationItem.rightBarButtonItem.enabled=YES;
            
            [currentManagers addObject:selectedUser];
            [self.tableView reloadData];
            
        }
        if (buttonIndex == 1){//Do not make manager
            
        }
    }
    if (alertView.tag==116){
        if (buttonIndex == 0){//Remove Manager
            //if they are the manager and there is another manager declared.
            if ([selectedUser.objectId isEqualToString:[PFUser currentUser].objectId]){
                if (currentManagers.count>1){
                    self.navigationItem.rightBarButtonItem.title=@"Save";
                    self.navigationItem.rightBarButtonItem.enabled=YES;
                    
                    isManager=NO;
                    [currentManagers removeObject:selectedUser];
                    [self.tableView reloadData];
                }
                else{
                    UIAlertView * readwrite = [[UIAlertView alloc] initWithTitle:@"Needs a manager" message:@"You can only remove yourself if there is another manager declared." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
                    [readwrite show];
                }
            }
            else{
                self.navigationItem.rightBarButtonItem.title=@"Save";
                self.navigationItem.rightBarButtonItem.enabled=YES;
                
                [currentManagers removeObject:selectedUser];
                [self.tableView reloadData];
            }
        }
        if (buttonIndex == 1){//Do not make manager
            
        }
    }
    if (alertView.tag==700){
        if (buttonIndex == 1){//send
            //send to some parse function that checks the email and sends the invite.
            [PFCloud callFunctionInBackground:@"teamEmail"
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
}

- (void) addBuddy{
    //Add them to current user's buddy list.
    PFQuery *queryUser = [PFQuery queryWithClassName:@"_User"];
    
    [queryUser getObjectInBackgroundWithId:[PFUser currentUser].objectId block:^(PFObject *object, NSError *error) {
        
        [object addUniqueObject:selectedUser forKey:@"buddies"];
        
        [object saveInBackgroundWithTarget:self selector:@selector(refreshBuddies)];
        
    }];
    
}
-(IBAction)savePFRole:(id)sender{
    [currentRole fetchIfNeeded];

    //make an acl with read:all and write:currentManagers
    PFACL * newACL =[PFACL ACL];
    [newACL setPublicReadAccess:YES];
    [newACL setPublicWriteAccess:YES];
    //set the managers.
    for (PFUser * user in currentManagers){
        [newACL setWriteAccess:YES forUser:user];
    }
    currentRole.ACL=newACL;

    [currentRole saveInBackground];
    self.navigationItem.rightBarButtonItem.title=@"Saved";
    self.navigationItem.rightBarButtonItem.enabled=NO;
  
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
