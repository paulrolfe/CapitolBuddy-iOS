//
//  IAPHelper.h
//  CapitolBuddy
//
//  Created by Paul Rolfe on 9/11/13.
//  Copyright (c) 2013 Paul Rolfe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "DataLoader.h"
UIKIT_EXTERN NSString *const IAPHelperProductPurchasedNotification;
UIKIT_EXTERN NSString *const kSubscriptionExpirationDateKey;

typedef void (^RequestProductsCompletionHandler)(BOOL success, NSArray * products);

@interface IAPHelper : NSObject

- (id)initWithProductIdentifiers:(NSSet *)productIdentifiers;
- (void)requestProductsWithCompletionHandler:(RequestProductsCompletionHandler)completionHandler;
- (void)provideContentForProductIdentifier:(NSString *)productIdentifier;

- (BOOL)restoreCompletedTransactionsForProducts:(NSArray *)products;

- (int)daysRemainingOnSubscriptionForProduct:(NSString *)productIdentifier;
- (NSDate *)getExpirationDateForProduct:(NSString *)productIdentifier;
- (NSString *)getExpirationDateStringForProduct: (NSString *)productIdentifier;

@end
