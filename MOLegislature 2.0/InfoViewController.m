//
//  InfoViewController.m
//  MOLegislature 2.0
//
//  Created by Paul Rolfe on 2/26/13.
//  Copyright (c) 2013 Paul Rolfe. All rights reserved.
//

#import "InfoViewController.h"

@interface InfoViewController ()

@end

@implementation InfoViewController
@synthesize currentLeg;
@synthesize currentImage;
@synthesize currentDistrict;
@synthesize currentEmail;
@synthesize currentParty;
@synthesize currentPhone;
@synthesize currentBio, currentComms, currentOffice, currentStaff, currentHometown;
@synthesize fileMgr,homeDir;
@synthesize backButton;


NSArray *newSenators;

-(NSString *)GetDocumentDirectory{
    fileMgr = [NSFileManager defaultManager];
    homeDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    
    return homeDir;
}

//used if coming from the info button in vote count views. Unattached, because attachement is created on viewing.
- (IBAction)backToVotesButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];

}

- (void)viewDidLoad
{
    
    [super viewDidLoad];
    [self configureView];
    //track the profile view.
    NSDictionary *dimensions = @{
                                 // Define ranges to bucket data points into meaningful segments
                                 @"legislator": currentLeg.name,
                                 // Do searches happen more often on weekdays or weekends?
                                 @"state": [[NSUserDefaults standardUserDefaults] objectForKey:@"state"]
                                 };
    // Send the dimensions to Parse along with the 'search' event
    [PFAnalytics trackEvent:@"Profile_Views" dimensions:dimensions];
}
- (void)setCurrentLeg:(Legs *)newCurrentLeg
{
    if (currentLeg != newCurrentLeg) {
        currentLeg = newCurrentLeg;
        
        // Update the view.
        [self configureView];
    }
    
}


- (void)configureView
{
    // Update the user interface for the detail item.
    
    if (backButton!=nil){
        self.navigationItem.leftBarButtonItem=backButton;
    }
    if (currentLeg.name==nil){
    
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            
            DetailViewManager *detailViewManager = (DetailViewManager*)self.splitViewController.delegate;

            // Create and configure a new detail view controller appropriate for the selection.
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
            UINavigationController *detailNavigationController = [storyboard instantiateViewControllerWithIdentifier:@"OptionsNavID"];
            
            detailViewManager.detailNavigationViewController = detailNavigationController;
        }
    }
   
    [self setTitle:currentLeg.name];
    
    UILabel* tlabel=[[UILabel alloc] initWithFrame:CGRectMake(0,0, 200, 40)];
    tlabel.text=self.title;
    tlabel.textColor=[UIColor blackColor];
    tlabel.font = [UIFont fontWithName:@"Helvetica-Bold" size: 17.0];
    tlabel.textAlignment = NSTextAlignmentCenter;
    tlabel.backgroundColor =[UIColor clearColor];
    tlabel.adjustsFontSizeToFitWidth=YES;
    self.navigationItem.titleView=tlabel;
    
    [currentBio setScrollsToTop:NO];
    [currentComms setScrollsToTop:NO];
    [currentEmail setScrollsToTop:NO];
    [currentOffice setScrollsToTop:NO];
    
    //retrieve image from local directory.
    NSString *pngName = currentLeg.imageFile;
    NSString *pngPath = [self.GetDocumentDirectory stringByAppendingPathComponent:pngName];
    UIImage *image = [UIImage imageWithContentsOfFile: pngPath];
    [self.currentImage setImage:image];
    
    //Set Legislator Details
    [currentDistrict setText:[NSString stringWithFormat:@"(%@) District %@",currentLeg.hstype,currentLeg.district]];
    [currentPhone setTitle:currentLeg.phone forState:UIControlStateNormal];
    [currentParty setText:currentLeg.party];
    
    [currentOffice setText:currentLeg.office];

    
    //Make Office line fit right
    if (![[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        NSInteger lengthThreshold = 10;
        if( [ currentOffice.text length ] > lengthThreshold ) {
            NSInteger newSize = 12;
            [currentOffice setFont: [ UIFont systemFontOfSize: newSize ]];
        }
    }
    
    
    [currentStaff setText:currentLeg.staff];
    [currentEmail setText: currentLeg.email];

    if (![[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {

        
        NSInteger lengthThresholdEmail = 20;
        if( [ currentEmail.text length ] > lengthThresholdEmail ) {
            NSInteger newSize = 12;
            [currentEmail setFont: [ UIFont systemFontOfSize: newSize ]];
        }
    }
    
    [currentHometown setText:currentLeg.hometown];
    
    
    //Set the bio text to remove some characters...
    NSString * newBio =[currentLeg.bio stringByReplacingOccurrencesOfString:@"�" withString:@"'"];
    newBio =[newBio stringByReplacingOccurrencesOfString:@"﾿" withString: @"-"];
    newBio =[newBio stringByReplacingOccurrencesOfString:@";" withString: @"\n\n"];

    [currentBio setText:newBio];

    //Set the comms text to remove some characters...
    NSString * newComms = [currentLeg.comms stringByReplacingOccurrencesOfString:@";" withString: @"\n"];
    newComms =[newComms stringByReplacingOccurrencesOfString:@"﾿" withString: @"-"];
    

    [currentComms setText:newComms];



}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)websiteAction:(id)sender {
    [[UIApplication sharedApplication]openURL:[NSURL URLWithString:currentLeg.website]];
}

- (IBAction)recentNewsAction:(id)sender {
    
    //make the name url friendly
    NSString *nameAsURL=[currentLeg.name stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    //Get the state to query
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    NSString *state= [defaults objectForKey:@"state"];

    
    //get the rep or sen. Then go to webpage.
    if([currentLeg.hstype isEqualToString:@"H"]){
        NSString* senrep=@"Rep.";
        NSString *newsQuery=[@"http://www.google.com/search?tbm=nws&q=" stringByAppendingFormat:@"%@+%@+%@", state, senrep, nameAsURL];
        
        //Open the view where they can save news stories.
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
        APPDetailViewController * newsWindow = [storyboard instantiateViewControllerWithIdentifier:@"NewsSaverID"];
        UINavigationController *viewNavigationController = [[UINavigationController alloc] initWithRootViewController:newsWindow];
        
        
        [newsWindow setUrl:newsQuery];
        [newsWindow setTitle:currentLeg.name];
        
        [self presentViewController:viewNavigationController animated:YES completion:nil];
        
    }
    else{
        NSString *senrep=@"Sen.";
        NSString *newsQuery=[@"http://www.google.com/search?tbm=nws&q=" stringByAppendingFormat:@"%@+%@+%@", state, senrep, nameAsURL];
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
        APPDetailViewController * newsWindow = [storyboard instantiateViewControllerWithIdentifier:@"NewsSaverID"];
        UINavigationController *viewNavigationController = [[UINavigationController alloc] initWithRootViewController:newsWindow];

        
        [newsWindow setUrl:newsQuery];
        [newsWindow setTitle:currentLeg.name];
        
        [self presentViewController:viewNavigationController animated:YES completion:nil];
        
    }
    
}

- (IBAction)phoneAction:(id)sender {
    NSString *tele = [NSString stringWithFormat:@"tel:%@",currentLeg.phone];
    [[UIApplication sharedApplication]openURL:[NSURL URLWithString:tele]];
}


-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if ([[segue identifier] isEqualToString: @"NotesSegue"]){
        NotesTableViewController *ivc=[segue destinationViewController];
        [ivc setCurrentLegNotes:currentLeg];
    }
  
}
-(void) viewDidDisappear:(BOOL)animated{

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
        
        _navigationPaneBarButtonItem = navigationPaneBarButtonItem;


    }
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}
- (IBAction)suggestCorrectionAction:(id)sender {
    SubmitCorrectionViewController * submitWindow = [self.storyboard instantiateViewControllerWithIdentifier:@"SubmitID"];
    [submitWindow setCurrentLeg:currentLeg];
    [self presentViewController:submitWindow animated:YES completion:nil];
    
}
@end
