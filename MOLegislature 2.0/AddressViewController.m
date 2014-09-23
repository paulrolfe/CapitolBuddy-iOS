//
//  AddressViewController.m
//  CapitolBuddy
//
//  Created by Paul Rolfe on 3/19/14.
//  Copyright (c) 2014 Paul Rolfe. All rights reserved.
//

#import "AddressViewController.h"

@interface AddressViewController ()

@end

@implementation AddressViewController
@synthesize streetLine,cityLine,zipLine,stateLine,lookUpMode;

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
    
    streetLine.delegate=self;
    cityLine.delegate=self;
    zipLine.delegate=self;
    stateLine.delegate=self;
    
	// set the fields as Parse knows them. (if it's for MY LEGISLATORS)
    if (!lookUpMode){
        [[PFUser currentUser] fetchInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            if (!error){
                streetLine.text = object[@"street"];
                cityLine.text = object[@"city"];
                zipLine.text = object[@"zip"];
                stateLine.text = object[@"state"];
                [self reloadInputViews];
            }
        }];
    }
    else{
        self.title=@"Enter Address";
        if (![[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
            self.navigationItem.leftBarButtonItem=[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu-icon.png"] style:UIBarButtonItemStylePlain target:self action:@selector(showLeftMenuPressed:)];
        }
    }
}
- (BOOL) textFieldShouldReturn:(UITextField *)textField{
    if (textField==streetLine){
        [cityLine becomeFirstResponder];
    }
    else if (textField==cityLine){
        [stateLine becomeFirstResponder];
    }
    else if (textField==stateLine){
        [zipLine becomeFirstResponder];
    }
    else if (textField==zipLine){
        [self searchButton:self];
    }
    
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
- (IBAction)searchButton:(id)sender {
    
    [PFAnalytics trackEvent:@"AddressLookup"];

    //send a cloud function to Parse that translates the address to coordinates.
    [PFCloud callFunctionInBackground:@"findDistricts"
                       withParameters:@{@"senderID" : [PFUser currentUser].objectId,
                                        @"street" : streetLine.text,
                                        @"city" : cityLine.text,
                                        @"zip" : zipLine.text,
                                        @"state" : stateLine.text,
                                        @"lookUpMode" : [NSNumber numberWithBool:lookUpMode]}
                                block:^(NSString *result, NSError *error) {
                                    if (!error) {
                                        NSArray * resultArray =[result componentsSeparatedByString:@";"];

                                        if (!lookUpMode){

                                        //store the response districts in a setting called myDistricts and myState;
                                        [[NSUserDefaults standardUserDefaults] setObject:[resultArray objectAtIndex:0] forKey:@"myState"];
                                        [[NSUserDefaults standardUserDefaults] setObject:[resultArray objectAtIndex:1] forKey:@"mySen"];
                                        [[NSUserDefaults standardUserDefaults] setObject:[resultArray objectAtIndex:2] forKey:@"myRep"];
                                            [self.navigationController popViewControllerAnimated:YES];

                                        }
                                        else{
                                            MyLegsViewController * myLegs;

                                            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                                                // Create and configure a new detail view controller appropriate for the selection.
                                                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"PadStoryboard" bundle:[NSBundle mainBundle]];
                                                myLegs = [storyboard instantiateViewControllerWithIdentifier:@"MyLegsID"];
                                            }
                                            else{
                                                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
                                                myLegs = [storyboard instantiateViewControllerWithIdentifier:@"MyLegsID"];
                                            }
                                            
                                            [myLegs setLookUpMode:lookUpMode];
                                            [myLegs setLookedUpState:[resultArray objectAtIndex:0]];
                                            [myLegs setLookedUpSen:[resultArray objectAtIndex:1]];
                                            [myLegs setLookedUpRep:[resultArray objectAtIndex:2]];
                                            
                                            [self.navigationController pushViewController:myLegs animated:YES];
                                        }
                                    }
                                    else{
                                        
                                        UIAlertView * fail = [[UIAlertView alloc] initWithTitle:@"Error" message:[error userInfo][@"error"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                                        [fail show];
                                    }
                                }];
  
}
- (IBAction)showLeftMenuPressed:(id)sender {
    
    if (![[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
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
