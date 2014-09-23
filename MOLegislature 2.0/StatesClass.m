//
//  StatesClass.m
//  CapitolBuddy
//
//  Created by Paul Rolfe on 9/23/13.
//  Copyright (c) 2013 Paul Rolfe. All rights reserved.
//

#import "StatesClass.h"
#import "IAPHelper.h"

@implementation StatesClass

@synthesize displayName,expirationDateString,productIdentifier,stateCode;

- (id)initPurchasedProductsWithIdentifier: (NSString *)productId {
   
    IAPHelper * expDateGetter =[[IAPHelper alloc]init];
    
    if ((self = [super init])) {
        BOOL success = [expDateGetter daysRemainingOnSubscriptionForProduct:productId] > 0;
    
        if (success){
            NSString * expDate =[expDateGetter getExpirationDateStringForProduct:productId];
            NSString * stateAbbrev=[productId substringFromIndex:[productId length] -2];
            
            NSString *name =[[NSUserDefaults standardUserDefaults]objectForKey:stateAbbrev];
            
            self.productIdentifier = productId;
            self.expirationDateString =expDate;
            self.displayName = name;
            self.stateCode = stateAbbrev;
            
        }
    }
    return self;
}

@end
