//
//  NewMapViewController.h
//  CapitolBuddy
//
//  Created by Paul Rolfe on 5/6/14.
//  Copyright (c) 2014 Paul Rolfe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "DataLoader.h"
#import "DetailViewManager.h"
#import "MFSideMenu.h"
#import "Legs.h"
#import "InfoViewController.h"


@interface NewMapViewController : UIViewController<MKMapViewDelegate,CLLocationManagerDelegate,SubstitutableDetailViewController,UISearchBarDelegate,UISearchDisplayDelegate,UITableViewDelegate>{
    BOOL showHouse;
    NSMutableArray * overlayData;
    NSMutableArray * overlayDistricts;
    NSString * filePath;
    NSMutableDictionary * DistrictDictionary;
    CLLocationManager * manager;
    UIActivityIndicatorView * spinner;
    NSArray * searchResults;
    NSArray * legList;
    Legs * selectedLeg;
    NSString * SENATE_DICTIONARY;
    NSString * HOUSE_DICTIONARY;
}
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) UIBarButtonItem *navigationPaneBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *switchLabel;



- (IBAction)switchMaps:(id)sender;
- (IBAction)showLeftMenuPressed:(id)sender;



@end

@interface MyCustomAnnotation : MKPlacemark {
	CLLocationCoordinate2D coordinate_;
	NSString *title_;
	NSString *subtitle_;
}

// Re-declare MKAnnotation's readonly property 'coordinate' to readwrite.
@property (nonatomic, readwrite, assign) CLLocationCoordinate2D coordinate;

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *subtitle;
@property NSInteger tag;

@end