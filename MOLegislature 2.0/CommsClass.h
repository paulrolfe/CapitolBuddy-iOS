//
//  CommsClass.h
//  MOLegislature 3.0
//
//  Created by Paul Rolfe on 3/18/13.
//  Copyright (c) 2013 Paul Rolfe. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CommsClass : NSObject{
    //making the variables for each committee
    int _rowID;
    NSString *_hsType;
    NSString *_commName;
    NSString *_commURL;
    
}
@property int rowID;
@property (nonatomic, strong) NSString *hsType;
@property (nonatomic, strong) NSString *commName;
@property (nonatomic, strong) NSString *commURL;

//the function to create committee arays.
- (id)initWithUniqueId:(int)rowID hsType:(NSString *)hsType commName:(NSString *)commName commURL:(NSString *)commURL;

@end
