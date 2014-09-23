//
//  NewMapViewController.m
//  CapitolBuddy
//
//  Created by Paul Rolfe on 5/6/14.
//  Copyright (c) 2014 Paul Rolfe. All rights reserved.
//
#define SUNLIGHT_API_KEY    @"bdfca7a469084417b139cdfda7453cea"
#define SENATE_DICTIONARY   @"DistrictCoordinates_Senate"
#define HOUSE_DICTIONARY    @"DistrictCoordinates_House"

#import "NewMapViewController.h"

@interface NewMapViewController ()

@end

@implementation NewMapViewController
@synthesize mapView,switchLabel;

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
    
    self.mapView.showsUserLocation = YES;
    self.mapView.rotateEnabled=NO;
    self.mapView.pitchEnabled=NO;
    self.mapView.delegate=self;
    //switchLabel.enabled=NO;
    
    //grab the overlay points.
    [self getOverlayPointsForChamber];
    
    MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc] init];
    request.naturalLanguageQuery = [[NSUserDefaults standardUserDefaults] objectForKey:@"state"];
    
    MKLocalSearch *search = [[MKLocalSearch alloc]initWithRequest:request];
    
    [search startWithCompletionHandler:^(MKLocalSearchResponse
                                         *response, NSError *error) {
        if (response.mapItems.count == 0)
            NSLog(@"No Matches");
        else{
            MKMapItem * startState=[response.mapItems objectAtIndex:0];
            MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance (startState.placemark.location.coordinate, [(CLCircularRegion*)startState.placemark.region radius]*2,[(CLCircularRegion*)startState.placemark.region radius]*2);
            [self.mapView setRegion:region animated:YES];
        }
    }];
}
-(void)viewDidAppear:(BOOL)animated{
    //Start the location manager to know where they are... really this might not be needed, but it's for the location based notifications actually.
    if (manager==nil)
        manager = [[CLLocationManager alloc] init];
    manager.delegate = self;
    [manager startMonitoringSignificantLocationChanges];
    
}
-(void)viewDidDisappear:(BOOL)animated{
    [manager stopMonitoringSignificantLocationChanges];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void) getOverlayPointsForChamber{
    [mapView removeOverlays:mapView.overlays];
    [mapView removeAnnotations:mapView.annotations];
    spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    spinner.frame = CGRectMake(self.view.frame.size.width/2-50, self.view.frame.size.height/2-50, 100, 100);
    [self.view addSubview:spinner];
    [spinner startAnimating];
    
    if (showHouse){
        filePath = [[DataLoader database].GetDocumentDirectory stringByAppendingPathComponent:HOUSE_DICTIONARY];
        disDic = [[NSMutableDictionary alloc] initWithContentsOfFile:filePath];
        //if there's no dictionary in storage, ask sunlight.
        if (disDic==nil)
            [self getMapDataFromSunlightForChamber:@"lower"];
        //otherwise, turn the dictionary into our points.
        else{
            NSLog(@"Items in disDic: %lu",(unsigned long)disDic.count);
            NSEnumerator * goThru = [disDic objectEnumerator];
            id value;
            overlayData = [[NSMutableArray alloc] init];
            while ((value = [goThru nextObject])) {
                /* code that acts on the dictionary’s values */
                [overlayData addObject:[self getCoordinatesFromDictionary:value]];
            }
            [self addOverlaysToMap];

        }
    }
    else{
        filePath = [[DataLoader database].GetDocumentDirectory stringByAppendingPathComponent:SENATE_DICTIONARY];
        disDic = [[NSMutableDictionary alloc] initWithContentsOfFile:filePath];
        if (disDic==nil)
            [self getMapDataFromSunlightForChamber:@"upper"];
        //otherwise, turn the dictionary into our points.
        else{
            NSEnumerator * goThru = [disDic objectEnumerator];
            id value;
            overlayData = [[NSMutableArray alloc] init];
            while ((value = [goThru nextObject])) {
                /* code that acts on the dictionary’s values */
                [overlayData addObject:[self getCoordinatesFromDictionary:value]];
            }
            [self addOverlaysToMap];

        }
    }
}
-(void) getMapDataFromSunlightForChamber:(NSString *)upperLower{
    //Ask sunlight for a list of all the districts in a chamber and get the district ID's
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSString * query = [NSString stringWithFormat:@"http://openstates.org/api/v1//districts/ri/%@/?apikey=%@",upperLower,SUNLIGHT_API_KEY];
        NSData *response = [NSData dataWithContentsOfURL:[NSURL URLWithString:query]];
        NSError* error;
        NSArray * json = [NSJSONSerialization
                              JSONObjectWithData: response //1
                              options:0
                              error:&error];
        overlayData = [[NSMutableArray alloc] init];
        disDic = [[NSMutableDictionary alloc] init];
        //for each district, add an array of the coordinates that make up its boundary.
        for (int i=0; i < json.count; i++){
            [overlayData addObject:[self executeSunlightFetchForBoundaryId: json[i][@"boundary_id"] ]];
        }
        
        [disDic writeToFile:filePath atomically:YES];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //update main thread here.
            //using the array of array of boundary points, add the overlays.
            [self addOverlaysToMap];
        });
    });
    
}
- (NSArray *)executeSunlightFetchForBoundaryId:(NSString *)boundaryId{
    //Get the boundary points for the given district
    NSString * query = [NSString stringWithFormat:@"http://openstates.org/api/v1//districts/boundary/%@/?apikey=%@",boundaryId,SUNLIGHT_API_KEY];
    NSData *response = [NSData dataWithContentsOfURL:[NSURL URLWithString:query]];
    NSError* error;
    NSDictionary * json = [NSJSONSerialization
                      JSONObjectWithData: response
                      options:0
                      error:&error];
    //Set the set of points for the boundary in the masterdictionary
    [disDic setObject:json forKey:boundaryId];
    NSLog(@"Items in disDic: %lu",(unsigned long)disDic.count);
    
    //Get the coordinates into the right format in an array.
    return [self getCoordinatesFromDictionary:json];
}
-(NSArray *)getCoordinatesFromDictionary:(NSDictionary *)dict{
    
    //from the dictionary, get the coordinates.
    NSArray * coords = dict[@"shape"][0][0];
    NSMutableArray * realCoords = [[NSMutableArray alloc] init];
    NSLog(@"%lu coords from district %@",(unsigned long)coords.count,dict[@"name"]);
    NSArray * zones = dict[@"shape"];
    for (int z=0; z<zones.count;z++){
        for (int i=0; i<coords.count; i++){
            double lat = [dict[@"shape"][0][0][i][0] doubleValue];
            double lon = [dict[@"shape"][0][0][i][1] doubleValue];
            //NSLog(@"lon: %f\nlat: %f",lat,lon);
            CLLocationCoordinate2D loc = CLLocationCoordinate2DMake(lon, lat);
            NSValue * locValue = [NSValue valueWithMKCoordinate:loc];
            [realCoords addObject:locValue];
        }
    }
    
    return realCoords;
}
-(void) addOverlaysToMap{
    if (showHouse){
        //for each coordinate array in the overlayarray
        for (int i=0; i < overlayData.count; i++){
            NSArray * theseCoords = overlayData[i];
            NSInteger count = ((NSArray *)overlayData[i]).count;
            
            CLLocationCoordinate2D  points[count];
            
            //for each coordinate in the array
            for (int r=0;r<count;r++){
                points[r]=[theseCoords[r] MKCoordinateValue];
            }
            MKPolygon* poly = [MKPolygon polygonWithCoordinates:points count:count];
            poly.title =[NSString stringWithFormat:@"House Distict %u",i];
#warning int i is not actually it's district.

            //create a pin for the new start place.
            MyCustomAnnotation *annot = [[MyCustomAnnotation alloc] initWithCoordinate:poly.coordinate addressDictionary:nil];
            annot.title = poly.title;
            //annot.subtitle = [NSString stringWithFormat:@"District %@",poly.subtitle];
            
            [self.mapView addAnnotation:annot];
            [self.mapView addOverlay:poly];
        }
    }
    else{
        //for each coordinate array in the overlayarray
        for (int i=0; i < overlayData.count; i++){
            NSArray * theseCoords = overlayData[i];
            NSInteger count = ((NSDictionary *)overlayData[i]).count;
            
            CLLocationCoordinate2D  points[count];

            //for each coordinate in the array
            for (int r=0;r<count;r++){
                points[r]=[theseCoords[r] MKCoordinateValue];
            }
            
            MKPolygon* poly = [MKPolygon polygonWithCoordinates:points count:count];
            poly.title =[NSString stringWithFormat:@"Senate Distict %u",i+1];
#warning int i is not actually it's district.

            //create a pin for the new start place.
            MyCustomAnnotation *annot = [[MyCustomAnnotation alloc] initWithCoordinate:poly.coordinate addressDictionary:nil];
            annot.title = poly.title;
            //annot.subtitle = [NSString stringWithFormat:@"District %@",poly.subtitle];
            
            [self.mapView addAnnotation:annot];
            [self.mapView addOverlay:poly];
        }
    }
    [spinner stopAnimating];
}
-(MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay{
    
    //from https://gist.github.com/kylefox/1689973
    MKPolygonRenderer* aRenderer = [[MKPolygonRenderer alloc] initWithPolygon:(MKPolygon*)overlay];
    CGFloat hue = ( arc4random() % 256 / 256.0 );  //  0.0 to 1.0
    CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from white
    CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from black
   
    aRenderer.fillColor= [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:.4];
    aRenderer.strokeColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.6];
    aRenderer.lineWidth = 2;
    
    return aRenderer;
}

-(MKAnnotationView *) mapView:(MKMapView *)mapview viewForAnnotation:(id<MKAnnotation>)annotation{
    // Try to dequeue an existing pin view first (code not shown).
    if ([annotation class]==[MKUserLocation class]) {
        return nil;
	}
    
	static NSString * const kPinAnnotationIdentifier = @"PinIdentifier";
    MKPinAnnotationView *customPinView= (MKPinAnnotationView *) [mapView dequeueReusableAnnotationViewWithIdentifier:kPinAnnotationIdentifier];
    if (customPinView == nil){
        customPinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:kPinAnnotationIdentifier];
    }
    customPinView.pinColor = MKPinAnnotationColorRed;
    customPinView.animatesDrop = NO;
    customPinView.canShowCallout = YES;
    customPinView.draggable=NO;
    
    // Because this is an iOS app, add the detail disclosure button to display details about the annotation in another view.
    /*UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
     [rightButton addTarget:nil action:nil forControlEvents:UIControlEventTouchUpInside];
     customPinView.rightCalloutAccessoryView = rightButton;
     
     // Add a custom image to the left side of the callout.
     UIImageView *myCustomImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"MyCustomImage.png"]];
     customPinView.leftCalloutAccessoryView = myCustomImage;*/
    
    return customPinView;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (IBAction)showLeftMenuPressed:(id)sender {
    [self.menuContainerViewController toggleLeftSideMenuCompletion:nil];
}
- (IBAction)switchMaps:(id)sender {
    //switching to show the Senate map next.
    if ([switchLabel.title isEqualToString:@"Senate"]){
        self.title = @"Senate District Map";
        switchLabel.title=@"House";
        showHouse=NO;
        [self getOverlayPointsForChamber];
        return;
    }
    //switching to show the house.
    if ([switchLabel.title isEqualToString:@"House"]){
        self.title = @"House District Map";
        switchLabel.title=@"Senate";
        showHouse=YES;
        [self getOverlayPointsForChamber];
    }
}

@end

@implementation MyCustomAnnotation

@synthesize coordinate = coordinate_;
@synthesize title = title_;
@synthesize subtitle = subtitle_;

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate addressDictionary:(NSDictionary *)addressDictionary {
	
	if ((self = [super initWithCoordinate:coordinate addressDictionary:addressDictionary])) {
		self.coordinate = coordinate;
	}
	return self;
}


@end
