//
//  AllNotesViewController.m
//  CapitolBuddy
//
//  Created by Paul Rolfe on 2/19/14.
//  Copyright (c) 2014 Paul Rolfe. All rights reserved.
//

#import "AllNotesViewController.h"

@interface AllNotesViewController ()

@end

@implementation AllNotesViewController

@synthesize segmentedControlBar,notesTabBar,shouldReloadNotes,badgeCount;


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Note Feed";
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(newNote:)];
    filePath = [[DataLoader database].GetDocumentDirectory stringByAppendingPathComponent:@"picDic"];
    picDic = [[NSMutableDictionary alloc] initWithContentsOfFile:filePath];
    loadingThreshold=100;
    
    [self.searchDisplayController.searchResultsTableView registerNib:[UINib nibWithNibName:@"BigNoteCell_nib" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"PublicCell"];
    self.searchDisplayController.searchBar.autocorrectionType=UITextAutocorrectionTypeNo;
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(loadNetworkNotes) forControlEvents:UIControlEventValueChanged];
    [self.tableview addSubview:self.refreshControl];
    
    if (![[PFUser currentUser] isAuthenticated] || [PFAnonymousUtils isLinkedWithUser:[PFUser currentUser]]){
        [self makeNotesTable:NO];
    }
    else{
        //if they're not anonymous, load the crap.
        if (![PFAnonymousUtils isLinkedWithUser:[PFUser currentUser]]){
            [self makeNotesTable:YES];
        }
    }
}
-(void) makeNotesTable:(BOOL)viewable{
    if (!viewable){
        UILabel * pleaseLogIn = [[UILabel alloc] initWithFrame:CGRectMake(40, 80, self.view.frame.size.width-80, 200)];
        pleaseLogIn.text=@"Please Log In\n\nTo use this feature, we ask you to log in so you don't lose any notes you save.";
        pleaseLogIn.numberOfLines=0;
        pleaseLogIn.lineBreakMode=NSLineBreakByWordWrapping;
        pleaseLogIn.font=[UIFont systemFontOfSize:15];
        pleaseLogIn.tag=5;
        
        //remove the table view and other things and add a button.
        [self.tableview setHidden:YES];
        [segmentedControlBar setHidden:YES];
        [notesTabBar setUserInteractionEnabled:NO];
        [self.navigationItem.rightBarButtonItem setEnabled:NO];
        shouldReloadNotes=NO;
        
        UIButton * logIn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2-100, self.view.frame.size.height/2-20, 200, 40)];
        logIn.tag=6;
        logIn.backgroundColor=[UIColor colorWithRed:0 green:.3 blue:.6 alpha:.7];
        [logIn setTitle:@"log in / sign up" forState:UIControlStateNormal];
        [logIn addTarget:self action:@selector(showLogIn) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:logIn];
        [self.view addSubview:pleaseLogIn];
    }
    if(viewable){
        //add the table view and things.
        [self.tableview setHidden:NO];
        [segmentedControlBar setHidden:NO];
        [notesTabBar setUserInteractionEnabled:YES];
        [self.navigationItem.rightBarButtonItem setEnabled:YES];
        shouldReloadNotes=YES;

        
        //remove the buttons and stuff
        [[self.view viewWithTag:5] removeFromSuperview];
        [[self.view viewWithTag:6] removeFromSuperview];
        
        [self loadCachedNotes];
        [self loadNetworkNotes];
        
        [segmentedControlBar addTarget:self
                                action:@selector(pickOne:)
                      forControlEvents:UIControlEventValueChanged];
        
        notesTabBar.selectedItem=[[notesTabBar items] objectAtIndex:0];
    }
}
-(void)viewWillAppear:(BOOL)animated{
    if (shouldReloadNotes){
        [self loadNetworkNotes];
        if ([[PFUser currentUser] isAuthenticated]){
            [self.refreshControl beginRefreshing];
            [self refreshRoles];
        }
    }
    if(!shouldReloadNotes)
        [self.tableview reloadData];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        if (UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation])){
            self.navigationItem.leftBarButtonItem=nil;
        }
    }
    if (badgeCount!=0)
        [[notesTabBar.items objectAtIndex:3] setBadgeValue:[NSString stringWithFormat:@"%d",badgeCount]];
}
-(void) loadCachedNotes{
    NotesObject * noteGuru = [[NotesObject alloc] init];
    allNotes =[noteGuru findAllMyNotesWithCachePolicy:kPFCachePolicyCacheOnly skip:0];
    [self filterAllNotes];
    [self pickOne:nil];
}
-(void) loadNetworkNotes{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NotesObject * noteGuru = [[NotesObject alloc] init];
        allNotes =[noteGuru findAllMyNotesWithCachePolicy:kPFCachePolicyNetworkElseCache skip:0];
        loadingThreshold=100;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //update main thread here.
            [self filterAllNotes];
            [self pickOne:nil];
            [self downloadProfilePics];
            [self loadShareAlerts];
            
        });
    });
}
-(void) filterAllNotes{
    myNotes = [[NSMutableArray alloc] init];
    publicNotes = [[NSMutableArray alloc] init];
    
    for (NotesObject * note in allNotes){
        if (note.isPublic){
            [publicNotes addObject:note];
        }
        if ([note.sharingSettings getReadAccessForUser:[PFUser currentUser]]){
            [myNotes addObject:note];
        }
    }
}

-(void)downloadProfilePics{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        //If there isn't a dictionary in the saved location, make one.
        if (picDic ==nil)
            picDic = [[NSMutableDictionary alloc] init];
        for (NotesObject * note in allNotes){//go through each owner in allnotes
            if (![picDic.allKeys containsObject:note.owner.objectId] || [(NSDate *)[picDic objectForKey:[note.owner.objectId stringByAppendingString:@"_date"]] timeIntervalSinceNow]<-60*60*24){//if there is no data yet... or it hasn't been updated in 24 hours.
                [note.owner fetchIfNeeded];
                PFFile * imageFile = note.owner[@"imageFile"];
                if (note.owner[@"imageFile"]!=nil){
                    NSData * data = [self resizeProfileImage:[imageFile getData]];
                    [picDic setObject:data forKey:note.owner.objectId];
                    //also get the username and real name for the cell views.
                    [picDic setObject:[NSDate date] forKey:[note.owner.objectId stringByAppendingString:@"_date"]];
                    [picDic setObject:note.owner.username forKey:[note.owner.objectId stringByAppendingString:@"_username"]];
                    [picDic setObject:note.owner[@"realName"] forKey:[note.owner.objectId stringByAppendingString:@"_realname"]];


                }
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            //update main thread here.
            [picDic writeToFile:filePath atomically:YES];
            [self pickOne:nil];
        });
    });

}
-(NSData *) resizeProfileImage:(NSData *)imageData{
    UIImage * imageProfile = [UIImage imageWithData:imageData];
    CGFloat realHeight = imageProfile.size.height;
    CGFloat realWidth = imageProfile.size.width;
    CGFloat newWidth = 100;
    CGFloat newHeight = (100 * realHeight)/realWidth;
    
    CGSize newSize=CGSizeMake(newWidth, newHeight);
    UIGraphicsBeginImageContext( newSize );
    [imageProfile drawInRect:CGRectMake(0,0,newWidth,newHeight)];
    
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    NSData * newData = UIImageJPEGRepresentation(newImage, 1);
    
    return newData;
}

-(void) loadShareAlerts{

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NotesObject * noteGuru = [[NotesObject alloc] init];
        newNotes = [noteGuru findNewNotesFromAlertsAndSetRead:NO];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //update main thread here.
            int newCount = 0;
            for (NotesObject * note in newNotes){
                if (note.isNew)
                    newCount++;
            }
            if (newCount!=0){
                badgeCount=newCount;
                [[notesTabBar.items objectAtIndex:3] setBadgeValue:[NSString stringWithFormat:@"%d",badgeCount]];
            }

            [self pickOne:nil];

        });
    });
}

-(void) refreshRoles{
    PFQuery * roleQuery = [PFRole query];
    [roleQuery whereKey:@"users" equalTo:[PFUser currentUser]];
    [roleQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error){
            teams = [[NSMutableArray alloc] initWithArray:objects];
            [self usersInRoles:objects];
            [self pickOne:nil];
        }
        else
            NSLog(@"Error: %@ %@", error, [error userInfo]);
    }];
}
- (void)usersInRoles:(NSArray *)roles{
    
    teamCount = [[NSMutableArray alloc] init];
    
    for (PFRole * role in roles){
        [role fetchIfNeeded];
        PFQuery * usercountquery = [role.users query];
        usercountquery.cachePolicy=kPFCachePolicyCacheElseNetwork;
        [usercountquery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            NSString * count = [NSString stringWithFormat:@"%lu",(unsigned long)objects.count];
            [teamCount addObject:count];
        }];
    }
}
- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item{
    switch (item.tag) {
        case 0:
            //All Notes
            self.title = @"My Notes";
            [segmentedControlBar setTitle:@"By Others" forSegmentAtIndex:2];
            [segmentedControlBar setTitle:@"By Me" forSegmentAtIndex:1];
            [self pickOne:nil];
            break;
        case 1:
            //Team Notes: add a team button, alert of teams list where you choose which one to see.
            [self showTableOfTeams];
            [segmentedControlBar setTitle:@"By Others" forSegmentAtIndex:2];
            [segmentedControlBar setTitle:@"By Me" forSegmentAtIndex:1];
            break;
        case 2:
            self.title = @"Public Notes";
            [segmentedControlBar setTitle:@"Most Up's" forSegmentAtIndex:2];
            [segmentedControlBar setTitle:@"By Me" forSegmentAtIndex:1];
            [self pickOne:nil];
            break;
        case 3:
            //New Notes
            self.title = @"Note Inbox";
            [segmentedControlBar setTitle:@"Read Only" forSegmentAtIndex:2];
            [segmentedControlBar setTitle:@"Editable" forSegmentAtIndex:1];
            [[notesTabBar.items objectAtIndex:3] setBadgeValue:nil];
            badgeCount=0;
            segmentedControlBar.selectedSegmentIndex=0;
            //set the notes as read when the tab is clicked.
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                NotesObject * noteGuru = [[NotesObject alloc] init];
                [noteGuru findNewNotesFromAlertsAndSetRead:YES];
            });
            [self pickOne:nil];
            break;
    }
}
-(void) pickOne:(id)sender{
    [self.refreshControl endRefreshing];
    [footerView setHidden:YES];
    
    switch (segmentedControlBar.selectedSegmentIndex) {
        case 0:
            //Show all notes
            if (notesTabBar.selectedItem.tag==0) //for the all notes tab
                notesToDisplay=myNotes;
            if (notesTabBar.selectedItem.tag==1){ //for the team notes tab
                if (team)
                    [self filterForTeam];
                notesToDisplay=notesTeamToDisplay;
            }
            if (notesTabBar.selectedItem.tag==2){ //for the public notes tab.
                notesToDisplay=publicNotes;
                NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"updatedDate" ascending:NO];
                [notesToDisplay sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
            }
            if (notesTabBar.selectedItem.tag==3) //for the new notes tab
                notesToDisplay=newNotes;

            [self.tableview reloadData];
            break;
        case 1:
            //Show MY notes
            if (notesTabBar.selectedItem.tag==0) //for the all notes tab
                notesToDisplay=[self filterToMyNotes:myNotes];
            if (notesTabBar.selectedItem.tag==1){ //for the team notes tab
                if (team)
                    [self filterForTeam];
                notesToDisplay=[self filterToMyNotes:notesTeamToDisplay];
            }
            if (notesTabBar.selectedItem.tag==2) //for the public notes tab.
                notesToDisplay=[self filterToMyNotes:publicNotes];
            if (notesTabBar.selectedItem.tag==3) //for the new notes tab
                notesToDisplay=[self filterToEditableNotes:newNotes];

            [self.tableview reloadData];
            break;
        case 2:
            //Show OTHERS notes or MOST POPULAR
            if (notesTabBar.selectedItem.tag==0) //for the all notes tab
                notesToDisplay=[self filterToSharedNotes:myNotes];
            if (notesTabBar.selectedItem.tag==1){ //for the team notes tab
                if (team)
                    [self filterForTeam];
                notesToDisplay=[self filterToSharedNotes:notesTeamToDisplay];
            }
            if (notesTabBar.selectedItem.tag==2){ //for the public notes tab.
                notesToDisplay=publicNotes;
                NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"upCount" ascending:NO];
                [notesToDisplay sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
            }
            if (notesTabBar.selectedItem.tag==3) //for the new notes tab
                notesToDisplay=[self filterToReadOnlyNotes:newNotes];

            [self.tableview reloadData];
            break;
        default:
            break;
    }
}

- (NSMutableArray *) filterToMyNotes:(NSMutableArray *)array{
    NSMutableArray * thisArray = [[NSMutableArray alloc] init];
    
    for (NotesObject * note in array) {
        if ([note.owner.objectId isEqualToString:[PFUser currentUser].objectId]){
            [thisArray addObject:note];
        }
    }
    return thisArray;
}
- (NSMutableArray *) filterToSharedNotes:(NSMutableArray *)array{
    NSMutableArray * thisArray = [[NSMutableArray alloc] init];
    
    for (NotesObject * note in array) {
        if (![note.owner.objectId isEqualToString:[PFUser currentUser].objectId]){
            [thisArray addObject:note];
        }
    }
    return thisArray;
}
- (NSMutableArray *) filterToEditableNotes:(NSMutableArray *)array{
    NSMutableArray * thisArray = [[NSMutableArray alloc] init];
    
    for (NotesObject * note in array) {
        if (note.isEditable){
            [thisArray addObject:note];
        }
    }
    return thisArray;
}
- (NSMutableArray *) filterToReadOnlyNotes:(NSMutableArray *)array{
    NSMutableArray * thisArray = [[NSMutableArray alloc] init];
    
    for (NotesObject * note in array) {
        if (!note.isEditable){
            [thisArray addObject:note];
        }
    }
    return thisArray;
}
- (void) filterForTeam{
    notesTeamToDisplay = [[NSMutableArray alloc] init];
    
    //[team fetchIfNeeded];
    
    for (NotesObject * note in allNotes) {
        //check if the write or read access contains the pfrole object.
        for(PFObject * role in note.writeAccess){
            if([role.objectId isEqualToString:team.objectId]){
                [notesTeamToDisplay addObject:note];
            }
        }
        for(PFObject *role in note.readAccess){
            if([role.objectId isEqualToString:team.objectId]){
                [notesTeamToDisplay addObject:note];
            }
        }
    }
}
- (void) showTableOfTeams{
    UITableViewController * teamTableView = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
    UINavigationController * teamNav = [[UINavigationController alloc] initWithRootViewController:teamTableView];
    teamTableView.tableView.delegate=self;
    teamTableView.tableView.dataSource=self;
    teamTableView.tableView.tag=6;
    teamTableView.navigationItem.prompt=@"View notes for which team?";
    teamTableView.navigationItem.title=@"My Teams";
    teamTableView.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelTableOfTeams)];
    teamTableView.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit Teams" style:UIBarButtonItemStylePlain target:self action:@selector(goToTeamManager)];
    [self presentViewController:teamNav animated:YES completion:nil];
    [teamTableView.tableView reloadData];
}
- (void) cancelTableOfTeams{
    [self dismissViewControllerAnimated:YES completion:nil];
    notesTabBar.selectedItem=[[notesTabBar items] objectAtIndex:0];
    self.title = @"Public Notes";
    [self pickOne:nil];

}
- (void) goToTeamManager{
    [self dismissViewControllerAnimated:YES completion:^{
        TeamManagerViewController * tmvc = [self.storyboard instantiateViewControllerWithIdentifier:@"TeamManagerID"];
        UINavigationController * teamNav = [[UINavigationController alloc] initWithRootViewController:tmvc];
        tmvc.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(dismissModalViewControllerAnimated:)];
        [self presentViewController:teamNav animated:YES completion:nil];
    }];
    notesTabBar.selectedItem=[[notesTabBar items] objectAtIndex:0];
    self.title = @"Public Notes";
    [self pickOne:nil];
    
}
- (void)filterContentForSearchText:(NSString*)searchText
{
    NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"(noteText contains[cd] %@)", searchText];
    
    //First filter the local notes.
    searchResults = [[NSMutableArray alloc] initWithArray:[allNotes filteredArrayUsingPredicate:resultPredicate]];
    
    if (![searchText isEqualToString:@""]){
        //Then in the background query for more results. Like..
        PFQuery * noteQuery = [PFQuery queryWithClassName:@"Notes"];
        [noteQuery orderByAscending:@"savedDate"];
        [noteQuery whereKey:@"noteText" containsString:searchText];
        [noteQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            
            NSLog(@"%lu objects",(unsigned long)objects.count);
            
            if (!error){
                //add this array to the search results array and reload tableview.
                for (PFObject * object in objects){
                    NotesObject * newNote = [[NotesObject alloc] initWithPFObject:object];
                    if (![newNote findIfArray:allNotes ContainsNoteObject:newNote]){
                        [searchResults addObject: newNote];
                    }
                }
                NSLog(@"%lu objects in total search results",(unsigned long)searchResults.count);

                [self.searchDisplayController.searchResultsTableView reloadData];
            }
        }];
    }
}

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller
shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString];
    
    return YES;
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
    if (tableView==self.searchDisplayController.searchResultsTableView){
        return searchResults.count;
    }
    else{
        if (notesTabBar.selectedItem.tag==0){ //for the all notes tab
            return notesToDisplay.count;
        }
        if (notesTabBar.selectedItem.tag==1){ //for the all teams tab
            if (tableView.tag==6){
                return teams.count;
            }
            else{
                return notesToDisplay.count;
            }
        }
        if (notesTabBar.selectedItem.tag==2){
            return notesToDisplay.count;
        }
        if (notesTabBar.selectedItem.tag==3){ //for the new notes tab
            return notesToDisplay.count;
        }
        else
            return 0;
    }
}
- (CGFloat)tableView:(UITableView *)tableView
heightForFooterInSection:(NSInteger)section {
    //differ between your sections or if you
    //have only on section return a static value
    if (allNotes.count>=loadingThreshold && tableView.tag!=6 && tableView!=self.searchDisplayController.searchResultsTableView){
        if (notesTabBar.selectedItem.tag==1 && notesTeamToDisplay.count<loadingThreshold) //for the team notes tab
            return 0;
        else
            return 50;
    }
    else
        return 0;
}
-(UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    if (allNotes.count>=loadingThreshold && tableView.tag!=6){
        //allocate the view if it doesn't exist yet
        if (footerView==nil){
            footerView = [[UIView alloc] init];
            footerView.tag=allNotes.count;
            
            //create the button
            UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2-150, 3, 300, 44)];
            [button setBackgroundColor:[UIColor colorWithRed:0 green:.3 blue:.6 alpha:.7]];
            
            //set title, font size and font color
            [button setTitle:@"Load More Notes" forState:UIControlStateNormal];
            [button.titleLabel setFont:[UIFont boldSystemFontOfSize:20]];
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            
            //set action of the button
            [button addTarget:self action:@selector(loadMoreNotes)
             forControlEvents:UIControlEventTouchUpInside];
            
            //add the button to the view
            [footerView addSubview:button];
            //return the view for the footer
            footerView.hidden=YES;
        }
        return footerView;
    }
    else{
        return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CustomCell = @"PublicCell";
    BigNoteCell * cell=(BigNoteCell *)[tableView dequeueReusableCellWithIdentifier:CustomCell];
    if (cell == nil)
        cell = [[BigNoteCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CustomCell];
    
    NotesObject * noteInfo;

    // Configure the cell...
    if (tableView==self.searchDisplayController.searchResultsTableView){
        noteInfo=[searchResults objectAtIndex:indexPath.row];
        cell.timeLabel.text=[noteInfo timeSinceLastSave];
    }
    else{
        if (indexPath.row>=notesToDisplay.count-1)
            footerView.hidden=NO;
        
        if (notesTabBar.selectedItem.tag==0){ //for the all notes tab
            noteInfo =[notesToDisplay objectAtIndex:indexPath.row];
            cell.timeLabel.text=[noteInfo timeSinceLastSave];

        }
        if (notesTabBar.selectedItem.tag==1){ //for the team notes tab
            if (tableView.tag==6){//show the teams
                static NSString *CellIdentifier = @"Cell";
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
                if (cell == nil){
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
                }
                team =[teams objectAtIndex:indexPath.row];
                cell.textLabel.text = team.name;
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ members",[teamCount objectAtIndex:indexPath.row]];
                cell.contentView.backgroundColor=[UIColor colorWithRed:1 green:1 blue:.5 alpha:1];
                cell.textLabel.textColor = [UIColor blackColor];
                cell.detailTextLabel.textColor = [UIColor blackColor];
                
                return cell;
            }
            if (tableView==self.tableview){
                noteInfo =[notesToDisplay objectAtIndex:indexPath.row];
                cell.timeLabel.text=[noteInfo timeSinceLastSave];
            }
        }
        if (notesTabBar.selectedItem.tag==2){
            noteInfo =[notesToDisplay objectAtIndex:indexPath.row];
            cell.timeLabel.text=[noteInfo timeSinceLastSave];
        }
        if (notesTabBar.selectedItem.tag==3){ //for the inbox of notes tab
            noteInfo =[notesToDisplay objectAtIndex:indexPath.row];
            cell.timeLabel.text=[noteInfo timeSinceShared];
        }
    }
    if (noteInfo.isPublic)
        [cell setArrowsVisible:YES];
    if (!noteInfo.isPublic)
        [cell setArrowsVisible:NO];
    if (noteInfo.isEditable)
        cell.readOnlyView.imageView.image=[UIImage imageNamed:@"Pencil-black.png"];
    if (!noteInfo.isEditable)
        cell.readOnlyView.imageView.image=[UIImage imageNamed:@"eye-01.png"];
    if (noteInfo.writeAccess.count>1 || noteInfo.readAccess.count>1)
        cell.sharedButtonView.hidden=NO;
    if (!(noteInfo.writeAccess.count>1) && !(noteInfo.readAccess.count>1))
        cell.sharedButtonView.hidden=YES;
    
    cell.usernameLabel.text = [picDic objectForKey:[noteInfo.owner.objectId stringByAppendingString:@"_username"]];
    cell.realnameLabel.text = [picDic objectForKey:[noteInfo.owner.objectId stringByAppendingString:@"_realname"]];
    cell.noteTextLabel.text = noteInfo.noteText;
    cell.upCountCellLabel.text=[NSString stringWithFormat:@"%ld",(long)noteInfo.upCount];
    cell.downCountCellLabel.text=[NSString stringWithFormat:@"%ld",(long)noteInfo.downCount];
    UIImage * profileImage = [[UIImage alloc] initWithData:[picDic objectForKey:noteInfo.owner.objectId]];
    if (profileImage!=nil)
        cell.profileImageView.image=profileImage;
    
    return cell;
}
-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView.tag==6)
        return 44;
    else
        return 82;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    UIStoryboard * storyboard;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        storyboard = [UIStoryboard storyboardWithName:@"PadStoryboard" bundle:[NSBundle mainBundle]];
    }
    else{
        storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];

    }
    
    if (tableView==self.searchDisplayController.searchResultsTableView){
        NotesObject * selectedNote = [searchResults objectAtIndex:indexPath.row];
        NotesViewController * nvc = [storyboard instantiateViewControllerWithIdentifier:@"NoteViewID"];
        [nvc setCurrentNoteObject:selectedNote];
        [nvc setAntvc:self];
        [self.navigationController pushViewController:nvc animated:YES];
    }
    else{
        if (notesTabBar.selectedItem.tag==0 || notesTabBar.selectedItem.tag==2 || notesTabBar.selectedItem.tag==3){ //for the all notes tab
            NotesObject * selectedNote = [notesToDisplay objectAtIndex:indexPath.row];
            selectedNote.isNew=NO;
            NotesViewController * nvc = [storyboard instantiateViewControllerWithIdentifier:@"NoteViewID"];
            [nvc setCurrentNoteObject:selectedNote];
            [nvc setAntvc:self];
            [self.navigationController pushViewController:nvc animated:YES];
        }
        if (notesTabBar.selectedItem.tag==3){
            badgeCount=0;
        }
        if (notesTabBar.selectedItem.tag==1){ //for the team notes tab
            if(tableView.tag==6){
                team =[teams objectAtIndex:indexPath.row];
                [self dismissViewControllerAnimated:YES completion:^{
                    //call some function that filters by team.
                    self.title=[NSString stringWithFormat:@"%@: Notes",team.name];
                    [self filterForTeam];
                    [self pickOne:nil];
                }];
            }
            if(tableView==self.tableview){
                NotesObject * selectedNote = [notesToDisplay objectAtIndex:indexPath.row];
                NotesViewController * nvc = [storyboard instantiateViewControllerWithIdentifier:@"NoteViewID"];
                [nvc setCurrentNoteObject:selectedNote];
                [nvc setAntvc:self];
                [self.navigationController pushViewController:nvc animated:YES];
            }
        }
    }
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    if(tableView.tag==6 || tableView==self.searchDisplayController.searchResultsTableView || notesTabBar.selectedItem.tag==2)
        return NO;
    else
        return YES;
}
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        if (tableView==self.searchDisplayController.searchResultsTableView){
            //delete object at search results
            NotesObject * noteToDelete = [[NotesObject alloc] init];
            noteToDelete = [searchResults objectAtIndex:indexPath.row];
            [noteToDelete deleteNote];
            //[searchResults removeObjectAtIndex:indexPath.row];
            [allNotes removeObject:noteToDelete];
            [notesToDisplay removeObject:noteToDelete];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
        else{
            //delete object from display array
            NotesObject * noteToDelete = [[NotesObject alloc] init];
            noteToDelete = [notesToDisplay objectAtIndex:indexPath.row];
            [noteToDelete deleteNote];
            [notesToDisplay removeObject:noteToDelete];
            [allNotes removeObject:noteToDelete];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
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
- (IBAction)newNote:(id)sender{
    NotesViewController * nvc = [self.storyboard instantiateViewControllerWithIdentifier:@"NoteViewID"];
    
    NotesObject * notesGuru = [[NotesObject alloc]init];
    [nvc setCurrentNoteObject:[notesGuru makeNewNote:nil]];
    [nvc setAntvc:self];
    
    [self.navigationController pushViewController:nvc animated:YES];
    
}
-(void)loadMoreNotes{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        footerView.tag=allNotes.count;
        NotesObject * noteGuru = [[NotesObject alloc] init];
        [allNotes addObjectsFromArray:[noteGuru findAllMyNotesWithCachePolicy:kPFCachePolicyNetworkElseCache skip:footerView.tag]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //update main thread here.
            loadingThreshold=loadingThreshold+100;
            footerView.tag=allNotes.count;
            [footerView removeFromSuperview];
            [self filterAllNotes];
            [self pickOne:nil];
            [self downloadProfilePics];
            [self loadShareAlerts];
            [self.tableview scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:notesToDisplay.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];

            
        });
    });
}


- (IBAction)showLeftMenuPressed:(id)sender {

    [(SideMenuViewController *) self.menuContainerViewController.leftMenuViewController setNoteAlertCount:badgeCount];
    [[(SideMenuViewController *) self.menuContainerViewController.leftMenuViewController tableView] reloadData];
    [self.menuContainerViewController toggleLeftSideMenuCompletion:nil];
    
}
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
-(void)showLogIn{
    // Create the log in view controller
    PFLogInViewController *logInViewController = [[PFLogInViewController alloc] init];
    [logInViewController.logInView setLogo:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"CB_text.png"]]];
    [logInViewController.logInView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"CB_background.png"]]];
    logInViewController.logInView.usernameField.backgroundColor=[UIColor colorWithWhite:0.5 alpha:0.4];
    logInViewController.logInView.passwordField.backgroundColor=[UIColor colorWithWhite:0.5 alpha:0.4];
    logInViewController.logInView.signUpLabel.text=@"Sign up to back up your notes and purchases.";
    logInViewController.logInView.signUpLabel.textColor=[UIColor colorWithWhite:1 alpha:1];
    logInViewController.logInView.signUpButton.backgroundColor=[UIColor clearColor];
    [logInViewController.logInView.dismissButton setFrame: CGRectMake(10.0f, 10.0f,60.0f, 60.0f)];
    
    PFSignUpViewController *signUpViewController = [[PFSignUpViewController alloc] init];
    [signUpViewController.signUpView setLogo:[[UIImageView alloc]initWithImage:[UIImage imageNamed:@"CB_text.png"]]];
    [signUpViewController.signUpView.dismissButton setFrame:CGRectMake(10.0f, 10.0f, 60.0f, 60.0f)];
    [signUpViewController.signUpView setBackgroundColor:[UIColor colorWithWhite:.8 alpha:1]];
    signUpViewController.signUpView.usernameField.backgroundColor=[UIColor colorWithWhite:0.5 alpha:0.4];
    signUpViewController.signUpView.passwordField.backgroundColor=[UIColor colorWithWhite:0.5 alpha:0.4];
    signUpViewController.signUpView.emailField.backgroundColor=[UIColor colorWithWhite:0.5 alpha:0.4];
    [signUpViewController setDelegate:self]; // Set ourselves as the delegate
    
    // Assign our sign up controller to be displayed from the login controller
    [logInViewController setSignUpController:signUpViewController];
    
    [logInViewController setDelegate:self];
    [self presentViewController:logInViewController animated:YES completion:NULL];
}
#pragma mark - PFLogInViewControllerDelegate

// Sent to the delegate to determine whether the log in request should be submitted to the server.
- (BOOL)logInViewController:(PFLogInViewController *)logInController shouldBeginLogInWithUsername:(NSString *)username password:(NSString *)password {
    // Check if both fields are completed
    if (username && password && username.length && password.length) {
        return YES; // Begin login process
    }
    
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Missing Information", nil) message:NSLocalizedString(@"Make sure you fill out all of the information!", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
    return NO; // Interrupt login process
}

// Sent to the delegate when a PFUser is logged in.
- (void)logInViewController:(PFLogInViewController *)logInController didLogInUser:(PFUser *)user {
    [self dismissViewControllerAnimated:YES completion:NULL];
    [self makeNotesTable:YES];
    
    //restore notes and vote counts
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        DataLoader *dbCrud=[[DataLoader alloc] init];
        [dbCrud CopyDbToDocumentsFolder];
        [dbCrud DownloadNewPhotos];
        
    });
    
}

// Sent to the delegate when the log in attempt fails.
- (void)logInViewController:(PFLogInViewController *)logInController didFailToLogInWithError:(NSError *)error {
    NSLog(@"Failed to log in...");
}

// Sent to the delegate when the log in screen is dismissed.
- (void)logInViewControllerDidCancelLogIn:(PFLogInViewController *)logInController {
    [self dismissViewControllerAnimated:YES completion:nil];
    [PFUser enableAutomaticUser];
    [[PFUser currentUser] saveInBackground];
}
#pragma mark - PFSignUpViewControllerDelegate

// Sent to the delegate to determine whether the sign up request should be submitted to the server.
- (BOOL)signUpViewController:(PFSignUpViewController *)signUpController shouldBeginSignUp:(NSDictionary *)info {
    BOOL informationComplete = YES;
    
    // loop through all of the submitted data
    for (id key in info) {
        NSString *field = [info objectForKey:key];
        if (!field || !field.length) { // check completion
            informationComplete = NO;
            break;
        }
    }
    
    // Display an alert if a field wasn't completed
    if (!informationComplete) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Missing Information", nil) message:NSLocalizedString(@"Make sure you fill out all of the information!", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
    }
    
    return informationComplete;
}

// Sent to the delegate when a PFUser is signed up.
- (void)signUpViewController:(PFSignUpViewController *)signUpController didSignUpUser:(PFUser *)user {
    [self dismissViewControllerAnimated:YES completion:NULL];
    [self makeNotesTable:YES];

}

// Sent to the delegate when the sign up attempt fails.
- (void)signUpViewController:(PFSignUpViewController *)signUpController didFailToSignUpWithError:(NSError *)error {
    NSLog(@"Failed to sign up...");
}

// Sent to the delegate when the sign up screen is dismissed.
- (void)signUpViewControllerDidCancelSignUp:(PFSignUpViewController *)signUpController {
    NSLog(@"User dismissed the signUpViewController");
}
@end
