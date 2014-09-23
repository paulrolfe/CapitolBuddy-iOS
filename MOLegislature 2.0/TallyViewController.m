//
//  TallyViewController.m
//  CapitolBuddy
//
//  Created by Paul Rolfe on 9/24/13.
//  Copyright (c) 2013 Paul Rolfe. All rights reserved.
//

#import "TallyViewController.h"

@interface TallyViewController ()

@end

@implementation TallyViewController
@synthesize GoodVotesLabel,BadVotesLabel,SwingVotesLabel;
@synthesize thisBill;
@synthesize LegislatorsAll;

NSMutableArray *newGoodVotes;
NSMutableArray *newBadVotes;
NSMutableArray *newSwingVotes;

NSMutableArray *theDs;

NSMutableArray *gVotes;
NSMutableArray *bVotes;
NSMutableArray *sVotes;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self refreshData];
    [self reloadInputViews];
    self.navBarTitle.topItem.title = thisBill.billName;
    //track the Vote Count view.
    [PFAnalytics trackEvent:@"VoteCount_Views"];
    
    
}
-(void)viewWillAppear:(BOOL)animated{
    [self refreshData];

}
- (IBAction)backButton:(id)sender {
    [self.tabBarController dismissViewControllerAnimated:YES completion:NULL];
}

-(void) refreshData{
    
    //load the correct list of legislators

    
    NSArray *theBills = [DataLoader database].savedBills;
    for (VoteTrackers * eachBill in theBills){
        if (eachBill.uniqueRowID == thisBill.uniqueRowID){
            thisBill=eachBill;
        }
    }
    if ([thisBill.billHStype isEqualToString:@"H"]){
        LegislatorsAll = [DataLoader database].representatives;
    }
    if ([thisBill.billHStype isEqualToString:@"S"]){
        LegislatorsAll = [DataLoader database].senators;
    }
    
    gVotes = [[NSMutableArray alloc]init];
    for (NSNumber * legIndex in thisBill.goodVotes){
        NSUInteger newIndex=[legIndex intValue];
        if (newIndex == 711){
            //nothing.
        }
        else{
            [gVotes addObject:[LegislatorsAll objectAtIndex:newIndex]];
        }
    }
    bVotes = [[NSMutableArray alloc]init];
    for (NSNumber * legIndex in thisBill.badVotes){
        NSUInteger newIndex=[legIndex intValue];
        if (newIndex ==711){
            //nothing.
        }
        else{
            [bVotes addObject:[LegislatorsAll objectAtIndex:newIndex]];
        }
    }
    sVotes = [[NSMutableArray alloc]init];
    for (NSNumber * legIndex in thisBill.swingVotes){
        NSUInteger newIndex=[legIndex intValue];
        if (newIndex ==711){
            //nothing.
        }
        else{
            [sVotes addObject:[LegislatorsAll objectAtIndex:newIndex]];
        }
    }
    //convert ints to strings
    NSString *gCount = [NSString stringWithFormat:@"%lu",(unsigned long)gVotes.count];
    NSString *bCount = [NSString stringWithFormat:@"%lu",(unsigned long)bVotes.count];
    NSString *sCount = [NSString stringWithFormat:@"%lu",(unsigned long)sVotes.count];
    
    //Set labels for vote counts
	GoodVotesLabel.text = gCount;
    BadVotesLabel.text=bCount;
    SwingVotesLabel.text=sCount;
    
    //Set the tab badges.
    UITabBarItem * goodTab =[self.tabBarController.tabBar.items objectAtIndex:1];
    goodTab.badgeValue = [NSString stringWithFormat:@"%lu",(unsigned long)thisBill.goodVotes.count-1];
    
    UITabBarItem * swingTab =[self.tabBarController.tabBar.items objectAtIndex:2];
    swingTab.badgeValue = [NSString stringWithFormat:@"%lu",(unsigned long)thisBill.swingVotes.count-1];
    
    UITabBarItem * badTab =[self.tabBarController.tabBar.items objectAtIndex:3];
    badTab.badgeValue = [NSString stringWithFormat:@"%lu",(unsigned long)thisBill.badVotes.count-1];
    
    [self.view reloadInputViews];
}

- (IBAction)dAdderGood:(id)sender {
    DataLoader *dbCrud=[[DataLoader alloc] init];
    
    newGoodVotes = nil;
    newSwingVotes =nil;
    newBadVotes = nil;
    theDs = nil;
    
    theDs = [[NSMutableArray alloc]init];
    for (Legs * thisLeg in LegislatorsAll){
        if ([thisLeg.party isEqualToString:@"D"]){
            NSString * myIndex = [NSString stringWithFormat:@"%d",thisLeg.rowID-1];
            
            [theDs addObject:myIndex];
        }
    }
    newGoodVotes=[[NSMutableArray alloc]initWithArray:thisBill.goodVotes];
    newBadVotes=[[NSMutableArray alloc]initWithArray:thisBill.badVotes];
    newSwingVotes=[[NSMutableArray alloc]initWithArray:thisBill.swingVotes];
    
    [newGoodVotes removeObjectsInArray:theDs];
    [newBadVotes removeObjectsInArray:theDs];
    [newSwingVotes removeObjectsInArray:theDs];
    
    [newGoodVotes addObjectsFromArray:theDs];
    
    [dbCrud UpdateSavedBills:thisBill.uniqueRowID :newGoodVotes :newBadVotes :newSwingVotes];
    [self refreshData];
    
    
}

- (IBAction)rAdderGood:(id)sender {
    DataLoader *dbCrud=[[DataLoader alloc] init];
    
    newGoodVotes = nil;
    newSwingVotes =nil;
    newBadVotes = nil;
    theDs = nil;
    
    theDs = [[NSMutableArray alloc]init];
    for (Legs * thisLeg in LegislatorsAll){
        if ([thisLeg.party isEqualToString:@"R"]){
            NSString * myIndex = [NSString stringWithFormat:@"%d",thisLeg.rowID-1];
            
            [theDs addObject:myIndex];
        }
    }
    newGoodVotes=[[NSMutableArray alloc]initWithArray:thisBill.goodVotes];
    newBadVotes=[[NSMutableArray alloc]initWithArray:thisBill.badVotes];
    newSwingVotes=[[NSMutableArray alloc]initWithArray:thisBill.swingVotes];
    
    [newGoodVotes removeObjectsInArray:theDs];
    [newBadVotes removeObjectsInArray:theDs];
    [newSwingVotes removeObjectsInArray:theDs];
    
    [newGoodVotes addObjectsFromArray:theDs];
    
    [dbCrud UpdateSavedBills:thisBill.uniqueRowID :newGoodVotes :newBadVotes :newSwingVotes];
    [self refreshData];
    
}

- (IBAction)dAdderBad:(id)sender {
    DataLoader *dbCrud=[[DataLoader alloc] init];
    
    newGoodVotes = nil;
    newSwingVotes =nil;
    newBadVotes = nil;
    theDs = nil;
    
    theDs = [[NSMutableArray alloc]init];
    for (Legs * thisLeg in LegislatorsAll){
        if ([thisLeg.party isEqualToString:@"D"]){
            NSString * myIndex = [NSString stringWithFormat:@"%d",thisLeg.rowID-1];
            
            [theDs addObject:myIndex];
        }
    }
    newGoodVotes=[[NSMutableArray alloc]initWithArray:thisBill.goodVotes];
    newBadVotes=[[NSMutableArray alloc]initWithArray:thisBill.badVotes];
    newSwingVotes=[[NSMutableArray alloc]initWithArray:thisBill.swingVotes];
    
    [newGoodVotes removeObjectsInArray:theDs];
    [newBadVotes removeObjectsInArray:theDs];
    [newSwingVotes removeObjectsInArray:theDs];
    
    [newBadVotes addObjectsFromArray:theDs];
    
    [dbCrud UpdateSavedBills:thisBill.uniqueRowID :newGoodVotes :newBadVotes :newSwingVotes];
    [self refreshData];
}

- (IBAction)rAdderBad:(id)sender {
    DataLoader *dbCrud=[[DataLoader alloc] init];
    
    newGoodVotes = nil;
    newSwingVotes =nil;
    newBadVotes = nil;
    theDs = nil;
    
    theDs = [[NSMutableArray alloc]init];
    for (Legs * thisLeg in LegislatorsAll){
        if ([thisLeg.party isEqualToString:@"R"]){
            NSString * myIndex = [NSString stringWithFormat:@"%d",thisLeg.rowID-1];
            
            [theDs addObject:myIndex];
        }
    }
    newGoodVotes=[[NSMutableArray alloc]initWithArray:thisBill.goodVotes];
    newBadVotes=[[NSMutableArray alloc]initWithArray:thisBill.badVotes];
    newSwingVotes=[[NSMutableArray alloc]initWithArray:thisBill.swingVotes];
    
    [newGoodVotes removeObjectsInArray:theDs];
    [newBadVotes removeObjectsInArray:theDs];
    [newSwingVotes removeObjectsInArray:theDs];
    
    [newBadVotes addObjectsFromArray:theDs];
    
    [dbCrud UpdateSavedBills:thisBill.uniqueRowID :newGoodVotes :newBadVotes :newSwingVotes];
    [self refreshData];
    
}

- (IBAction)oneTwoAdderGood:(id)sender {
    DataLoader *dbCrud=[[DataLoader alloc] init];
    
    newGoodVotes = nil;
    newSwingVotes =nil;
    newBadVotes = nil;
    theDs = nil;
    
    theDs = [[NSMutableArray alloc]init];
    for (Legs * thisLeg in LegislatorsAll){
        
        NSPredicate *myPredicate = [NSPredicate predicateWithFormat:@"(rating beginswith[cd] %@) OR (rating beginswith[cd] %@)",@"1",@"2"];
        
        BOOL match = [myPredicate evaluateWithObject:thisLeg];
        
        if (match){
            NSString * myIndex = [NSString stringWithFormat:@"%d",thisLeg.rowID-1];
            
            [theDs addObject:myIndex];
        }
    }
    newGoodVotes=[[NSMutableArray alloc]initWithArray:thisBill.goodVotes];
    newBadVotes=[[NSMutableArray alloc]initWithArray:thisBill.badVotes];
    newSwingVotes=[[NSMutableArray alloc]initWithArray:thisBill.swingVotes];
    
    [newGoodVotes removeObjectsInArray:theDs];
    [newBadVotes removeObjectsInArray:theDs];
    [newSwingVotes removeObjectsInArray:theDs];
    
    [newGoodVotes addObjectsFromArray:theDs];
    
    [dbCrud UpdateSavedBills:thisBill.uniqueRowID :newGoodVotes :newBadVotes :newSwingVotes];
    [self refreshData];
    
}

- (IBAction)fourFiveAdderGood:(id)sender {
    DataLoader *dbCrud=[[DataLoader alloc] init];
    
    newGoodVotes = nil;
    newSwingVotes =nil;
    newBadVotes = nil;
    theDs = nil;
    
    theDs = [[NSMutableArray alloc]init];
    for (Legs * thisLeg in LegislatorsAll){
        
        NSPredicate *myPredicate = [NSPredicate predicateWithFormat:@"(rating beginswith[cd] %@) OR (rating beginswith[cd] %@)",@"4",@"5"];
        
        BOOL match = [myPredicate evaluateWithObject:thisLeg];
        
        if (match){
            NSString * myIndex = [NSString stringWithFormat:@"%d",thisLeg.rowID-1];
            
            [theDs addObject:myIndex];
        }
    }
    newGoodVotes=[[NSMutableArray alloc]initWithArray:thisBill.goodVotes];
    newBadVotes=[[NSMutableArray alloc]initWithArray:thisBill.badVotes];
    newSwingVotes=[[NSMutableArray alloc]initWithArray:thisBill.swingVotes];
    
    [newGoodVotes removeObjectsInArray:theDs];
    [newBadVotes removeObjectsInArray:theDs];
    [newSwingVotes removeObjectsInArray:theDs];
    
    [newGoodVotes addObjectsFromArray:theDs];
    
    [dbCrud UpdateSavedBills:thisBill.uniqueRowID :newGoodVotes :newBadVotes :newSwingVotes];
    [self refreshData];
    
}


- (IBAction)oneTwoAdderBad:(id)sender {
    DataLoader *dbCrud=[[DataLoader alloc] init];
    
    newGoodVotes = nil;
    newSwingVotes =nil;
    newBadVotes = nil;
    theDs = nil;
    
    theDs = [[NSMutableArray alloc]init];
    for (Legs * thisLeg in LegislatorsAll){
        
        NSPredicate *myPredicate = [NSPredicate predicateWithFormat:@"(rating beginswith[cd] %@) OR (rating beginswith[cd] %@)",@"1",@"2"];
        
        BOOL match = [myPredicate evaluateWithObject:thisLeg];
        
        if (match){
            NSString * myIndex = [NSString stringWithFormat:@"%d",thisLeg.rowID-1];
            
            [theDs addObject:myIndex];
        }
    }
    newGoodVotes=[[NSMutableArray alloc]initWithArray:thisBill.goodVotes];
    newBadVotes=[[NSMutableArray alloc]initWithArray:thisBill.badVotes];
    newSwingVotes=[[NSMutableArray alloc]initWithArray:thisBill.swingVotes];
    
    [newGoodVotes removeObjectsInArray:theDs];
    [newBadVotes removeObjectsInArray:theDs];
    [newSwingVotes removeObjectsInArray:theDs];
    
    [newBadVotes addObjectsFromArray:theDs];
    
    [dbCrud UpdateSavedBills:thisBill.uniqueRowID :newGoodVotes :newBadVotes :newSwingVotes];
    [self refreshData];
}

- (IBAction)fourFiveAdderBad:(id)sender {
    DataLoader *dbCrud=[[DataLoader alloc] init];
    
    newGoodVotes = nil;
    newSwingVotes =nil;
    newBadVotes = nil;
    theDs = nil;
    
    theDs = [[NSMutableArray alloc]init];
    for (Legs * thisLeg in LegislatorsAll){
        
        NSPredicate *myPredicate = [NSPredicate predicateWithFormat:@"(rating beginswith[cd] %@) OR (rating beginswith[cd] %@)",@"4",@"5"];
        
        BOOL match = [myPredicate evaluateWithObject:thisLeg];
        
        if (match){
            NSString * myIndex = [NSString stringWithFormat:@"%d",thisLeg.rowID-1];
            
            [theDs addObject:myIndex];
        }
    }
    newGoodVotes=[[NSMutableArray alloc]initWithArray:thisBill.goodVotes];
    newBadVotes=[[NSMutableArray alloc]initWithArray:thisBill.badVotes];
    newSwingVotes=[[NSMutableArray alloc]initWithArray:thisBill.swingVotes];
    
    [newGoodVotes removeObjectsInArray:theDs];
    [newBadVotes removeObjectsInArray:theDs];
    [newSwingVotes removeObjectsInArray:theDs];
    
    [newBadVotes addObjectsFromArray:theDs];
    
    [dbCrud UpdateSavedBills:thisBill.uniqueRowID :newGoodVotes :newBadVotes :newSwingVotes];
    [self refreshData];

    
}

- (IBAction)threeAdderSwing:(id)sender {
    DataLoader *dbCrud=[[DataLoader alloc] init];
    
    newGoodVotes = nil;
    newSwingVotes =nil;
    newBadVotes = nil;
    theDs = nil;
    
    theDs = [[NSMutableArray alloc]init];
    for (Legs * thisLeg in LegislatorsAll){
        
        NSPredicate *myPredicate = [NSPredicate predicateWithFormat:@"(rating beginswith[cd] %@)",@"3"];
        
        BOOL match = [myPredicate evaluateWithObject:thisLeg];
        
        if (match){
            NSString * myIndex = [NSString stringWithFormat:@"%d",thisLeg.rowID-1];
            
            [theDs addObject:myIndex];
        }
    }
    newGoodVotes=[[NSMutableArray alloc]initWithArray:thisBill.goodVotes];
    newBadVotes=[[NSMutableArray alloc]initWithArray:thisBill.badVotes];
    newSwingVotes=[[NSMutableArray alloc]initWithArray:thisBill.swingVotes];
    
    [newGoodVotes removeObjectsInArray:theDs];
    [newBadVotes removeObjectsInArray:theDs];
    [newSwingVotes removeObjectsInArray:theDs];
    
    [newSwingVotes addObjectsFromArray:theDs];
    
    [dbCrud UpdateSavedBills:thisBill.uniqueRowID :newGoodVotes :newBadVotes :newSwingVotes];
    [self refreshData];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
