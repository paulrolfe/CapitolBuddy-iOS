//
//  AppDelegate.m
//  MOLegislature 2.0
//
//  Created by Paul Rolfe on 2/26/13.
//  Copyright (c) 2013 Paul Rolfe. All rights reserved.
//

#import "AppDelegate.h"



@implementation AppDelegate
@synthesize window, capitolCenter;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //load the settings
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    
    //This setting needs to be made so that a pop-up doesn't appear when you click on a legislator.
    [defaults setObject:@"NO" forKey:@"viewForLinkSave"];
    
    //track application opens
    [Parse setApplicationId:APPLICATION_ID clientKey:CLIENT_KEY];//Real Key
    //[Parse setApplicationId:APPLICATION_ID clientKey:CLIENT_KEY];//Dev Key
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    [PFACL setDefaultACL:[PFACL ACL] withAccessForCurrentUser:YES];
    if ([PFUser currentUser])
        [[PFUser currentUser] saveInBackground];
    
    // Register for push notifications
    [application registerForRemoteNotificationTypes: UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeBadge];
    
    //if there's no file at the notes location, then the state key needs to be set and the first data must be downloaded.
    if (![defaults boolForKey:@"firstTime"]){
        
        [defaults setObject:@"RI" forKey:@"state"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"kShouldDownloadNotes"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"kShouldDownloadVotes"];
        [defaults synchronize];
        
        DataLoader *dbCrud=[[DataLoader alloc] init];
        //copy the database
        [dbCrud CopyDbToDocumentsFolder];
        [dbCrud copyStringsToDocumentsFolder];

        
    }
    //Then in the background, load the photos and load the data again only if the notesdb exists.
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    
        DataLoader *dbCrud=[[DataLoader alloc] init];
        //copy the database

        //download the DBs if it isn't already happening (aka if it's not the first launch)
        if([defaults boolForKey:@"firstTime"]){
            [dbCrud CopyDbToDocumentsFolder];
            [dbCrud copyStringsToDocumentsFolder];
        }
        
        //copy the photos
        [dbCrud DownloadNewPhotos];
        
    });
    
    //Set state abbreviations
    [defaults setObject:@"Missouri" forKey:@"MO"];
    [defaults setObject:@"Rhode Island" forKey:@"RI"];
    [defaults setObject:@"Virginia" forKey:@"VA"];
    [defaults setObject:@"Illinois" forKey:@"IL"];
    [defaults setObject:@"Ohio" forKey:@"OH"];
    [defaults setObject:@"Pennsylvania" forKey:@"PA"];
    [defaults setObject:@"Kansas" forKey:@"KS"];
    [defaults setObject:@"New Jersey" forKey:@"NJ"];
    [defaults setObject:@"Massaschusetts" forKey:@"MA"];
    [defaults setObject:@"Minnesota" forKey:@"MN"];
    [defaults synchronize];
    
    //define the capitol's center.
    [self findCapitolBuilding];
    
    
    //set the ipad window
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
        UINavigationController *infoViewController = [storyboard instantiateViewControllerWithIdentifier:@"OptionsNavID"];
        
        UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
        
        self.detailViewManager = [[DetailViewManager alloc] init];
        self.detailViewManager.splitViewController = splitViewController;
        self.detailViewManager.detailNavigationViewController=infoViewController;
        splitViewController.delegate = self.detailViewManager;
        
        [self.window makeKeyAndVisible];
    }
    //set the iphone window
    else{
        //Instantiate the Side Menu and the center view
        //First get the tabbarcontroller of the legislators views
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
        UITabBarController *tbc = [storyboard instantiateViewControllerWithIdentifier:@"MainTabBar"];

    
        //Then put get the left side menu controller, but inside of a navcontroller
        sideMenu = [storyboard instantiateViewControllerWithIdentifier:@"SideMenu"];
        MFSideMenuContainerViewController *container = [MFSideMenuContainerViewController
                                                    containerWithCenterViewController:tbc
                                                    leftMenuViewController:sideMenu                                                   rightMenuViewController:nil];
    
        self.window.rootViewController = container;
        [self.window makeKeyAndVisible];
        
        //Handle the notification if opening from an alert (Responding to the Payload)
        // Extract the notification data
            
    }
    
#pragma mark - Purchase Registers
    [StateIAPHelper sharedInstance];
    
    DataLoader *toGetStrings = [[DataLoader alloc] init];
    NSString *filePath = [toGetStrings.GetDocumentDirectory stringByAppendingPathComponent:@"IAPstrings"];
    NSString * stateString = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    NSArray *stateObjects = [stateString componentsSeparatedByString:@"\n"];

    for (NSString * productIdentifier in stateObjects){
        // Use the product identifier from iTunes to register a handler.
        [PFPurchase addObserverForProduct:productIdentifier block:^(SKPaymentTransaction *transaction) {
            [PFPurchase downloadAssetForTransaction:transaction completion:^(NSString *filePath, NSError *error) {
                if (!error) {
                    // at this point, the content file is available at filePath. And I could download something that enables the user to gain access to the file in the cloud. But I'm not sure how to do that really.
                    [[StateIAPHelper sharedInstance] provideContentForProductIdentifier:productIdentifier];
                    
                }
            }];
        }];
    }
    
    
    //Set the tint color
    window.tintColor = [UIColor colorWithRed:0 green:.3 blue:.6 alpha:.7];
    
    
    if (launchOptions){
        UILocalNotification *notificationPayload = launchOptions[UIApplicationLaunchOptionsLocalNotificationKey];
        UIAlertView * noti = [[UIAlertView alloc] initWithTitle:@"CapitolBuddy" message:notificationPayload.alertBody delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [noti show];
    }

    return YES;
}


- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken {
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:newDeviceToken];
    if ([PFUser currentUser])
        currentInstallation[@"user"] = [PFUser currentUser];
    [currentInstallation saveInBackground];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    //if you get a note notification increase the appropriate badges. (No alert view)
    
    [sideMenu loadNoteBadge];

}
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    //[self startSignificantChangeUpdates];
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [self startSignificantChangeUpdates];

    
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [manager stopMonitoringSignificantLocationChanges];
    
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            DataLoader *dbCrud=[[DataLoader alloc] init];
            [dbCrud CopyDbToDocumentsFolder];
            [dbCrud DownloadNewPhotos];
            
        });
    
    [sideMenu loadNoteBadge];


}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    if (currentInstallation.badge != 0) {
        currentInstallation.badge = 0;
        [currentInstallation saveInBackground];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [self startSignificantChangeUpdates];

}
-(void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    UIAlertView * noti = [[UIAlertView alloc] initWithTitle:@"CapitolBuddy" message:notification.alertBody delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [noti show];
}
-(void) findCapitolBuilding{    
    //define the capitol's center.
    NSString * cap = [NSString  stringWithFormat:@"%@ State Capitol Building",[[NSUserDefaults standardUserDefaults] objectForKey:@"state"]];
    MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc] init];
    request.naturalLanguageQuery = cap;
    
    MKLocalSearch *search = [[MKLocalSearch alloc]initWithRequest:request];
    
    [search startWithCompletionHandler:^(MKLocalSearchResponse
                                         *response, NSError *error) {
        capitolCenter = ((MKMapItem *)response.mapItems[0]).placemark.location.coordinate;
    }];
}
- (void)startSignificantChangeUpdates{
    if (manager==nil)
        manager = [[CLLocationManager alloc] init];
    manager.delegate = self;

    CLCircularRegion * region = [[CLCircularRegion alloc] initWithCenter:capitolCenter radius:120 identifier:@"Capitol Building"];
    
    //Check this stuff before continuing.
    if (![CLLocationManager isMonitoringAvailableForClass:[region class]])
        return;
    if ([CLLocationManager authorizationStatus]!=kCLAuthorizationStatusAuthorized)
        return;
    if ([UIApplication sharedApplication].backgroundRefreshStatus==UIBackgroundRefreshStatusDenied){
        //show a warning
        return;
    }
    if ([UIApplication sharedApplication].backgroundRefreshStatus==UIBackgroundRefreshStatusRestricted)
        return;
        
    [manager startMonitoringForRegion:region];
}
-(void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region{
    //show a notification like: See if you can find any news on the legislators you're meeting with...
    UILocalNotification * hey = [[UILocalNotification alloc] init];
    hey.alertBody = @"You're in the Capitol! Need a buddy? Use CapitolBuddy to look up recent news and notes on legislators.";
    hey.soundName=UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication] scheduleLocalNotification:hey];
}
-(void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region{
    //show a notification that's like: Did you note everything about legislators?
    UILocalNotification * hey = [[UILocalNotification alloc] init];
    hey.alertBody = @"You left the Capitol. Did you remember to make a note for every meeting you had?";
    hey.soundName=UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication] scheduleLocalNotification:hey];
}


@end
