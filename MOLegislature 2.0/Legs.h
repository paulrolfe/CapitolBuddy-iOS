//
//  Legs.h
//  MOLegislature 2.0
//
//  Created by Paul Rolfe on 2/26/13.
//  Copyright (c) 2013 Paul Rolfe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DataLoader.h"

@interface Legs : NSObject{
    //gather the needed fields for each legislator
    int _rowID;
    NSString *_name;
    NSString *_district;
    NSString *_party;
    NSString *_office;
    NSString *_phone;
    NSString *_email;
    NSString *_website;
    NSString *_staff;
    NSString *_hometown;
    NSString *_bio;
    NSString *_notes;
    NSString *_hstype;
    NSString *_comms;
    NSString *_imageFile;
    NSString *_timeStamp;
    int _syncBool;
    NSString *_rating;
    NSString *_leadership;
}

//create a property for each variable
@property int rowID;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *district;
@property (nonatomic, strong) NSString *party;
@property (nonatomic, strong) NSString *office;
@property (nonatomic, strong) NSString *phone;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *website;
@property (nonatomic, strong) NSString *staff;
@property (nonatomic, strong) NSString *hometown;
@property (nonatomic, strong) NSString *bio;
@property (nonatomic, strong) NSString *notes;
@property (nonatomic, strong) NSString *hstype;
@property (nonatomic, strong) NSString *comms;
@property (nonatomic, strong) NSString *imageFile;
@property (nonatomic, strong) NSString *timeStamp;
@property int syncBool;
@property (nonatomic, strong) NSString *rating;
@property (nonatomic, strong) NSString *leadership;

//the function used to create arrays from the sqlite db
- (id)initWithUniqueId:(int)rowID name:(NSString *)name district:(NSString *)district party:(NSString *)party office:(NSString *)office phone:(NSString *)phone email:(NSString *)email website:(NSString *)website staff:(NSString *)staff hometown:(NSString *)hometown bio:(NSString *)bio notes:(NSString *)notes hstype:(NSString *)hstype comms:(NSString *)comms imageFile:(NSString *)imageFile timeStamp:(NSString *)timeStamp syncBool:(int)syncBool rating:(NSString *)rating leadership:(NSString *)leadership;

@end

