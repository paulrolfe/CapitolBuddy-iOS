//
//  LocationAlertMgr.h
//  CapitolBuddy
//
//  Created by Paul Rolfe on 5/6/14.
//  Copyright (c) 2014 Paul Rolfe. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@interface LocationAlertMgr : CLLocationManager<CLLocationManagerDelegate,MKMapViewDelegate>

@property CLLocationCoordinate2D capitolCenter;


@end
