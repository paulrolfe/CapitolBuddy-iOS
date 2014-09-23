//
//  Legs.m
//  MOLegislature 2.0
//
//  Created by Paul Rolfe on 2/26/13.
//  Copyright (c) 2013 Paul Rolfe. All rights reserved.
//

#import "Legs.h"

@implementation Legs

@synthesize rowID=_rowID;
@synthesize name=_name;
@synthesize district=_district;
@synthesize party=_party;
@synthesize office=_office;
@synthesize phone=_phone;
@synthesize email=_email;
@synthesize website=_website;
@synthesize staff=_staff;
@synthesize hometown=_hometown;
@synthesize bio=_bio;
@synthesize notes=_notes;
@synthesize hstype=_hstype;
@synthesize comms=_comms;
@synthesize imageFile=_imageFile;
@synthesize timeStamp=_timeStamp;
@synthesize syncBool=_syncBool;
@synthesize rating=_rating;
@synthesize leadership=_leadership;

//Define the function declared in the header.
- (id)initWithUniqueId:(int)rowID name:(NSString *)name district:(NSString *)district party:(NSString *)party office:(NSString *)office phone:(NSString *)phone email:(NSString *)email website:(NSString *)website staff:(NSString *)staff hometown:(NSString *)hometown bio:(NSString *)bio notes:(NSString *)notes hstype:(NSString *)hstype comms:(NSString *)comms imageFile:(NSString *)imageFile timeStamp:(NSString *)timeStamp syncBool:(int)syncBool rating:(NSString *)rating leadership:(NSString *)leadership{
    
    if ((self = [super init])) {
        self.rowID=rowID;
        self.name=name;
        self.district=district;
        self.party=party;
        self.office=office;
        self.phone=phone;
        self.email=email;
        self.website=website;
        self.staff=staff;
        self.hometown=hometown;
        self.bio=bio;
        self.notes=notes;
        self.hstype=hstype;
        self.comms=comms;
        self.imageFile=imageFile;
        self.timeStamp=timeStamp;
        self.syncBool=syncBool;
        self.rating=rating;
        self.leadership=leadership;
    }
    
        return self;
}


@end