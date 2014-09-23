//
//  LocationAlertMgr.m
//  CapitolBuddy
//
//  Created by Paul Rolfe on 5/6/14.
//  Copyright (c) 2014 Paul Rolfe. All rights reserved.
//

#import "LocationAlertMgr.h"

@implementation LocationAlertMgr
@synthesize capitolCenter;

-(id)init{
    self = [super init];
    if (self){
        self.delegate=self;
        [self findCapitolBuilding];
        [self startSignificantChangeUpdates];
    }
    return self;
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
- (void)startSignificantChangeUpdates
{

    [self startMonitoringSignificantLocationChanges];
    
    CLCircularRegion * region = [[CLCircularRegion alloc] initWithCenter:capitolCenter radius:100 identifier:@"Capitol Building"];
    
    [self startMonitoringForRegion:region];
}
-(void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region{
    //Assuming this all works, here is where you could show a notification.
    
}
@end
