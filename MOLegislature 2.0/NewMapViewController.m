//
//  NewMapViewController.m
//  CapitolBuddy
//
//  Created by Paul Rolfe on 5/6/14.
//  Copyright (c) 2014 Paul Rolfe. All rights reserved.
//
#define SUNLIGHT_API_KEY    @"bdfca7a469084417b139cdfda7453cea"


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
    
    SENATE_DICTIONARY = [NSString stringWithFormat:@"DistrictCoordinates_Senate_%@", [[NSUserDefaults standardUserDefaults] objectForKey:@"state"]];
    HOUSE_DICTIONARY =[NSString stringWithFormat:@"DistrictCoordinates_House_%@", [[NSUserDefaults standardUserDefaults] objectForKey:@"state"]];
    
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
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        if (UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation])){
            self.navigationItem.leftBarButtonItem=nil;
        }
    }
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
    if (spinner==nil)
        spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.frame = CGRectMake(self.view.frame.size.width/2-50, self.view.frame.size.height/2-50, 100, 100);
    [self.view addSubview:spinner];
    [spinner startAnimating];
    [self.searchDisplayController.searchBar setUserInteractionEnabled:NO];
    
    if (showHouse){
        filePath = [[DataLoader database].GetDocumentDirectory stringByAppendingPathComponent:HOUSE_DICTIONARY];
        DistrictDictionary = [[NSMutableDictionary alloc] initWithContentsOfFile:filePath];
        legList = [DataLoader database].representatives;
        //if there's no dictionary in storage, ask sunlight.
        if (DistrictDictionary==nil)
            [self getMapDataFromSunlightForChamber:@"lower"];
        //otherwise, turn the dictionary into our points.
        else{
            [self getCoordinatesFromDictionary];
            [self addOverlaysToMap];
        }
    }
    else{
        filePath = [[DataLoader database].GetDocumentDirectory stringByAppendingPathComponent:SENATE_DICTIONARY];
        DistrictDictionary = [[NSMutableDictionary alloc] initWithContentsOfFile:filePath];
        legList=[DataLoader database].senators;
        if (DistrictDictionary==nil)
            [self getMapDataFromSunlightForChamber:@"upper"];
        //otherwise, turn the dictionary into our points.
        else{
            [self getCoordinatesFromDictionary];
            [self addOverlaysToMap];
        }
    }
}
-(void) getMapDataFromSunlightForChamber:(NSString *)upperLower{
    //Ask sunlight for a list of all the districts in a chamber and get the district ID's
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSString * state = [[[NSUserDefaults standardUserDefaults] objectForKey:@"state"] lowercaseString];
        NSString * query = [NSString stringWithFormat:@"http://openstates.org/api/v1//districts/%@/%@/?apikey=%@",state,upperLower,SUNLIGHT_API_KEY];
        NSData *response = [NSData dataWithContentsOfURL:[NSURL URLWithString:query]];
        NSError* error;
        NSArray * json = [NSJSONSerialization
                              JSONObjectWithData: response //1
                              options:0
                              error:&error];
        overlayData = [[NSMutableArray alloc] init];
        DistrictDictionary = [[NSMutableDictionary alloc] init];
        //for each district, add an array of the coordinates that make up its boundary.
        for (int i=0; i < json.count; i++){
            [self executeSunlightFetchForBoundaryId:json[i][@"boundary_id"] ];
        }
        
        [DistrictDictionary writeToFile:filePath atomically:YES];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //update main thread here.
            //using the array of array of boundary points, add the overlays.
            [self getCoordinatesFromDictionary];
            [self addOverlaysToMap];
        });
    });
    
}
- (void)executeSunlightFetchForBoundaryId:(NSString *)boundaryId{
    //Get the boundary points for the given district
    NSString * query = [NSString stringWithFormat:@"http://openstates.org/api/v1//districts/boundary/%@/?apikey=%@",boundaryId,SUNLIGHT_API_KEY];
    NSData *response = [NSData dataWithContentsOfURL:[NSURL URLWithString:query]];
    NSError* error;
    NSDictionary * json = [NSJSONSerialization
                      JSONObjectWithData: response
                      options:0
                      error:&error];
    //Set the set of points for the boundary in the masterdictionary
    [DistrictDictionary setObject:json forKey:boundaryId];
    NSLog(@"Items in DistrictDictionary: %lu",(unsigned long)DistrictDictionary.count);
    
    //Get the coordinates into the right format in an array.
    //return [self getCoordinatesFromDictionary:json];
}
-(void)getCoordinatesFromDictionary{
    NSEnumerator * goThru = [DistrictDictionary objectEnumerator];
    id value;
    overlayData = [[NSMutableArray alloc] init];
    overlayDistricts = [[NSMutableArray alloc] init];
    while ((value = [goThru nextObject])) {
        /* code that acts on the dictionary’s values */
        
        //from the dictionary, get the coordinates.
        NSArray * zones = value[@"shape"];
        for (int z=0; z<zones.count;z++){
            NSArray * coords = value[@"shape"][z][0];
            NSMutableArray * realCoords = [[NSMutableArray alloc] init];
            NSLog(@"%lu coords from district %@",(unsigned long)coords.count,value[@"name"]);
            for (int i=0; i<coords.count; i++){
                double lat = [value[@"shape"][z][0][i][0] doubleValue];
                double lon = [value[@"shape"][z][0][i][1] doubleValue];
                //NSLog(@"lon: %f\nlat: %f",lat,lon);
                CLLocationCoordinate2D loc = CLLocationCoordinate2DMake(lon, lat);
                NSValue * locValue = [NSValue valueWithMKCoordinate:loc];
                [realCoords addObject:locValue];
            }
            [overlayData addObject:realCoords];
            [overlayDistricts addObject:value[@"name"]];
        }
    }
}
-(void) addOverlaysToMap{
    NSLog(@"Items in overlayData: %lu",(unsigned long)overlayData.count);
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
        poly.title = ((Legs *)[legList objectAtIndex:[overlayDistricts[i] integerValue]-1]).name;
        if (showHouse)
            poly.subtitle =[NSString stringWithFormat:@"House Distict %@",overlayDistricts[i]];
        else
            poly.subtitle=[NSString stringWithFormat:@"Senate Distict %@",overlayDistricts[i]];
        
        //create a pin for the new start place.
        MyCustomAnnotation *annot = [[MyCustomAnnotation alloc] initWithCoordinate:poly.coordinate addressDictionary:nil];
        annot.title = poly.title;
        annot.subtitle=poly.subtitle;
        annot.tag=[overlayDistricts[i] integerValue];
        
        [self.mapView addAnnotation:annot];
        [self.mapView addOverlay:poly];
    }
    [spinner stopAnimating];
    [self.searchDisplayController.searchBar setUserInteractionEnabled:YES];


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
    //the tags are district numbers.
    customPinView.tag=((MyCustomAnnotation *)annotation).tag;
    
    // Because this is an iOS app, add the detail disclosure button to display details about the annotation in another view.
    UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    [rightButton addTarget:nil action:nil forControlEvents:UIControlEventTouchUpInside];
     customPinView.rightCalloutAccessoryView = rightButton;
    
     // Add a custom image to the left side of the callout.
    //retrieve image from local directory.
    NSString *pngName = ((Legs *)[legList objectAtIndex:((MyCustomAnnotation *)annotation).tag-1]).imageFile;
    NSString *pngPath = [[DataLoader database].GetDocumentDirectory stringByAppendingPathComponent:pngName];
    UIImage *image = [UIImage imageWithContentsOfFile: pngPath];
    UIImageView * smallImage = [[UIImageView alloc] initWithImage:image];
    smallImage.frame = CGRectMake(0, 0, 44, 44);
    smallImage.contentMode=UIViewContentModeScaleAspectFit;
    customPinView.leftCalloutAccessoryView=smallImage;
    
    return customPinView;
}
-(void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control{
    selectedLeg = (Legs * )[legList objectAtIndex:view.tag-1];
    [self goToDistrictInfo];
}
- (void)filterContentForSearchText:(NSString*)searchText
{
    NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"(name contains[cd] %@) OR (district contains[cd] %@)",searchText, searchText];
    
    searchResults = [legList filteredArrayUsingPredicate:resultPredicate];
}

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller
shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString];
    
    return YES;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView)
        return [searchResults count];
    else
        return 0;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"SenateCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    //SearchResults View
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        Legs * current2 = [searchResults objectAtIndex:[indexPath row]];
        [[cell textLabel] setText:[current2 name]];
        cell.detailTextLabel.text=[NSString stringWithFormat:@"(%@) District %@ -- %@",current2.hstype, current2.district, current2.party];
        cell.detailTextLabel.backgroundColor=[UIColor clearColor];
        cell.textLabel.backgroundColor=[UIColor clearColor];
        
        cell.detailTextLabel.textColor=[UIColor colorWithWhite:0.0 alpha:.8];
        
        //retrieve image from local directory.
        NSString *pngName = current2.imageFile;
        NSString *pngPath = [[DataLoader database].GetDocumentDirectory stringByAppendingPathComponent:pngName];
        UIImage *image = [UIImage imageWithContentsOfFile: pngPath];
        [[cell imageView] setImage:image];
        
        cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
        UIView * myBG = [[UIView alloc] initWithFrame:CGRectZero];
        if ([current2.party isEqualToString:@"D"]) {
            myBG.backgroundColor = [UIColor colorWithRed:0.1 green:0.3 blue:0.5 alpha:0.6];
        }
        if ([current2.party isEqualToString:@"R"]) {
            myBG.backgroundColor = [UIColor colorWithRed:0.8 green:0.3 blue:0.1 alpha:0.6];
        }
        if ([current2.party isEqualToString:@"I"]){
            myBG.backgroundColor = [UIColor colorWithRed:0.3 green:0.1 blue:0.3 alpha:0.6];
        }
        if ([current2.party isEqualToString:@"NONE"]){
            myBG.backgroundColor = [UIColor whiteColor];
        }
        cell.backgroundView=myBG;
        
        [[cell.contentView viewWithTag:125] removeFromSuperview];
        if (![current2.leadership isEqualToString:@"NONE"]){
            CGRect imageRect = {182,26,130,17};
            UILabel * label = [[UILabel alloc] initWithFrame:imageRect];
            label.textAlignment = NSTextAlignmentCenter;
            label.backgroundColor=[UIColor colorWithWhite:.1 alpha:.5];
            label.textColor = [UIColor whiteColor];
            label.font=[UIFont systemFontOfSize:10];
            label.text = current2.leadership;
            label.tag=125;
            [cell.contentView addSubview:label];
        }
    }
    return cell;
}

#pragma mark - Navigation

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //dismiss the search display.
    [self.searchDisplayController setActive:NO animated:YES];
    
    //zoom to the region containing that district.
    NSString * chosenDistrict = ((Legs *)[searchResults objectAtIndex:indexPath.row]).district;
    NSUInteger mapIndex=[overlayDistricts indexOfObject:chosenDistrict];
    
    //make that annotation be up.
    NSArray * selectedPoints = [overlayData objectAtIndex:mapIndex];
    NSInteger count = selectedPoints.count;
    CLLocationCoordinate2D  points[count];
    //for each coordinate in the array
    for (int r=0;r<count;r++){
        points[r]=[selectedPoints[r] MKCoordinateValue];
    }
    MKPolygon* poly = [MKPolygon polygonWithCoordinates:points count:count];
    [self.mapView setVisibleMapRect:poly.boundingMapRect animated:YES];
    for (MyCustomAnnotation * annot in self.mapView.annotations){
        if ([annot class]!=[MKUserLocation class]){
            if (annot.tag==[chosenDistrict integerValue])
                [mapView selectAnnotation:annot animated:FALSE];
        }
    }

    //(MyCustomAnnotation *)[[self.mapView annotations] objectAtIndex:mapIndex];
}


#pragma mark - Navigation
/*
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
// -------------------------------------------------------------------------------
//	setNavigationPaneBarButtonItem:
//  Custom implementation for the navigationPaneBarButtonItem setter.
//  In addition to updating the _navigationPaneBarButtonItem ivar, it
//  reconfigures the toolbar to either show or hide the
//  navigationPaneBarButtonItem.
// -------------------------------------------------------------------------------
- (void)setNavigationPaneBarButtonItem:(UIBarButtonItem *)navigationPaneBarButtonItem
{
    if (navigationPaneBarButtonItem != _navigationPaneBarButtonItem) {
        if (navigationPaneBarButtonItem)
            [self.navigationItem setLeftBarButtonItem: navigationPaneBarButtonItem
                                             animated:NO];
        else
            [self.navigationItem setLeftBarButtonItem:nil
                                             animated:NO];
    }
    
    _navigationPaneBarButtonItem = navigationPaneBarButtonItem;
    
    
}
-(void) goToDistrictInfo{
    UIStoryboard * storyboard;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        storyboard=[UIStoryboard storyboardWithName:@"PadStoryboard" bundle:[NSBundle mainBundle]];
    }
    else{
        storyboard=self.storyboard;
    }
    InfoViewController * theLegInfo = [storyboard instantiateViewControllerWithIdentifier:@"InfoID"];
    [theLegInfo setCurrentLeg:selectedLeg];
    [self.navigationController pushViewController:theLegInfo animated:YES];;

}
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
