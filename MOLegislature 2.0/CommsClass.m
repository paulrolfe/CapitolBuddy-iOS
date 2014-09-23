//
//  CommsClass.m
//  MOLegislature 3.0
//
//  Created by Paul Rolfe on 3/18/13.
//  Copyright (c) 2013 Paul Rolfe. All rights reserved.
//

#import "CommsClass.h"

@implementation CommsClass
@synthesize rowID=_rowID;
@synthesize hsType=_hsType;
@synthesize commName=_commName;
@synthesize commURL=_commURL;

-(id) initWithUniqueId:(int)rowID hsType:(NSString *)hsType commName:(NSString *)commName commURL:(NSString *)commURL{
    if ((self = [super init])) {
        self.rowID=rowID;
        self.hsType=hsType;
        self.commName=commName;
        self.commURL=commURL;
    }
    return self;
}


@end
