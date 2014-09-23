//
//  NewBillViewController.m
//  CapitolBuddy
//
//  Created by Paul Rolfe on 9/24/13.
//  Copyright (c) 2013 Paul Rolfe. All rights reserved.
//

#import "NewBillViewController.h"

@interface NewBillViewController ()

@end

@implementation NewBillViewController
@synthesize addedBillName,segmentOutlet;

NSString * HorS;

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

- (IBAction)cancelButton:(id)sender {
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"newBillName"];
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"newBillHS"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self dismissViewControllerAnimated:YES completion:NULL];

}
- (IBAction)segmentedHouseSenate:(id)sender {
    if(segmentOutlet.selectedSegmentIndex == 0)
    {
        HorS = @"S";
    }
    else if(segmentOutlet.selectedSegmentIndex == 1)
    {
        HorS = @"H";
    }
    
}

- (IBAction)addBillButton:(id)sender {
    
    if (HorS != nil){
        if (addedBillName.text !=nil){
        [[NSUserDefaults standardUserDefaults] setObject:addedBillName.text forKey:@"newBillName"];
        [[NSUserDefaults standardUserDefaults] setObject:HorS forKey:@"newBillHS"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self dismissViewControllerAnimated:YES completion:NULL];
        }
        else{
            UIAlertView *tellErr = [[UIAlertView alloc] initWithTitle:@"Oops" message:@"You need to specify 'House or Senate' and a name." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [tellErr show];
        }
    }
    else{
        UIAlertView *tellErr = [[UIAlertView alloc] initWithTitle:@"Oops" message:@"You need to specify 'House or Senate' and a name." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [tellErr show];
    }
    

}

@end
