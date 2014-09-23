//
//  StateIAPHelper.m
//  CapitolBuddy
//
//  Created by Paul Rolfe on 9/11/13.
//  Copyright (c) 2013 Paul Rolfe. All rights reserved.
//

#import "StateIAPHelper.h"
#import "DataLoader.h"

@implementation StateIAPHelper

+ (StateIAPHelper *)sharedInstance {
    static dispatch_once_t once;
    static StateIAPHelper * sharedInstance;
    dispatch_once(&once, ^{
        DataLoader *toGetStrings = [[DataLoader alloc] init];
        NSString *filePath = [toGetStrings.GetDocumentDirectory stringByAppendingPathComponent:@"IAPstrings"];
        NSString * stateString = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
        NSArray *stateObjects = [stateString componentsSeparatedByString:@"\n"];
        NSSet * productIdentifiers = [NSSet setWithArray:stateObjects];
        //NSSet * productIdentifiers = [NSSet setWithObjects:@"RedOstrich.CapitolBuddy.Universal.MO",@"RedOstrich.CapitolBuddy.Universal.RI", nil];
        sharedInstance = [[self alloc] initWithProductIdentifiers:productIdentifiers];
    });
    
    return sharedInstance;
}


@end
