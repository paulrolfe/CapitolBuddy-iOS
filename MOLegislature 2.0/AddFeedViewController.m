//
//  AddFeedViewController.m
//  CapitolBuddy
//
//  Created by Paul Rolfe on 12/21/13.
//  Copyright (c) 2013 Paul Rolfe. All rights reserved.
//

#import "AddFeedViewController.h"

@interface AddFeedViewController ()


@end

@implementation AddFeedViewController
@synthesize titleTextInput,urlTextInput;
@synthesize currentTitles, currentURLs;

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
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)addFeedButton:(id)sender {
    //Add the feeds to their feed strings.
    NSString * newFeedTitles = [NSString stringWithFormat:@"%@;%@",currentTitles,titleTextInput.text];
    NSString * newFeedURLs = [NSString stringWithFormat:@"%@;%@",currentURLs,urlTextInput.text];
    
    //Save to Parse.
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    
    NSString *keyStringURLs = [NSString stringWithFormat:@"stateNews_%@",[defaults objectForKey:@"state"]];
    NSString *keyStringTitles = [NSString stringWithFormat:@"rssTitles_%@",[defaults objectForKey:@"state"]];
    
    //update parse with this new order.
    PFQuery *firstQuery = [PFQuery queryWithClassName:@"News"];
    [firstQuery whereKey:@"userID" equalTo:[PFUser currentUser].objectId];
    [firstQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error){
        
        object[keyStringTitles]=newFeedTitles;
        object[keyStringURLs]=newFeedURLs;
        [object saveInBackground];
        
    }];
    
    EditRSSViewController * ervc = (EditRSSViewController *)[self presentingViewController];
    
    [ervc setFeedTitles:[[NSArray alloc] initWithArray:[newFeedTitles componentsSeparatedByString:@";"]]];
    [ervc setFeedURLs:[[NSArray alloc] initWithArray:[newFeedURLs componentsSeparatedByString:@";"]]];
    
    [self dismissViewControllerAnimated:YES completion:nil];
 
}

- (IBAction)cancelButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];

}
@end
