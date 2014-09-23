//
//  AppDelegate.h
//  MOLegislature 2.0
//
//  Created by Paul Rolfe on 2/26/13.
//  Copyright (c) 2013 Paul Rolfe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <sqlite3.h>
#import <MapKit/MapKit.h>
#import <Parse/Parse.h>
#import "StateIAPHelper.h"
#import "SideMenuViewController.h"
#import "Legs.h"
#import "CommsClass.h"
#import "DataLoader.h"
#import "SenateTableViewController.h"
#import "HouseTableViewController.h"
#import "CommTableViewController.h"
#import "MFSideMenu.h"
#import "DetailViewManager.h"


@class SideMenuViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate, CLLocationManagerDelegate,MKMapViewDelegate>{
    SideMenuViewController * sideMenu;
    CLLocationManager * manager;
    
}

@property (strong, nonatomic) UIWindow *window;
@property CLLocationCoordinate2D capitolCenter;

@property (nonatomic, retain) DetailViewManager *detailViewManager;

-(void) findCapitolBuilding;



@end
