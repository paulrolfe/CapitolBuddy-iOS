//
//  StatesClass.h
//  CapitolBuddy
//
//  Created by Paul Rolfe on 9/23/13.
//  Copyright (c) 2013 Paul Rolfe. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface StatesClass : NSObject

@property NSString * displayName;
@property NSString * productIdentifier;
@property NSString * expirationDateString;
@property NSString * stateCode;

- (id)initPurchasedProductsWithIdentifier: (NSString *)productId;

@end
