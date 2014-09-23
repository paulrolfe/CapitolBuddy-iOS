//
//  IAPHelper.m
//  CapitolBuddy
//
//  Created by Paul Rolfe on 9/11/13.
//  Copyright (c) 2013 Paul Rolfe. All rights reserved.
//

// 1
#import "IAPHelper.h"
#import <StoreKit/StoreKit.h>
#import <Parse/Parse.h>
#import "ChangeStateViewController.h"

NSString *const kSubscriptionExpirationDateKey = @"ExpirationDate";

// 2
@interface IAPHelper () <SKProductsRequestDelegate, SKPaymentTransactionObserver>
@end

@implementation IAPHelper {
    // 3
    SKProductsRequest * _productsRequest;
    // 4
    RequestProductsCompletionHandler _completionHandler;
    NSSet * _productIdentifiers;
    NSMutableSet * _purchasedProductIdentifiers;
}

NSString *const IAPHelperProductPurchasedNotification = @"IAPHelperProductPurchasedNotification";

//Next, add the initializer
- (id)initWithProductIdentifiers:(NSSet *)productIdentifiers {
    
    if ((self = [super init])) {
        
        
        [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"RedOstrich.CapitolBuddy.Universal.RI"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        
        // Store product identifiers
        _productIdentifiers = productIdentifiers;
        
        // Check for previously purchased products
        _purchasedProductIdentifiers = [NSMutableSet set];
        for (NSString * productIdentifier in _productIdentifiers) {
            BOOL productPurchased = [self daysRemainingOnSubscriptionForProduct:productIdentifier]>0;
            if (productPurchased) {
                [_purchasedProductIdentifiers addObject:productIdentifier];
                NSLog(@"Previously purchased: %@", productIdentifier);
            } else {
                NSLog(@"Not purchased: %@", productIdentifier);
            }
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        }
        
    }
    return self;
}
//Next, add the method to retrieve the product information from iTunes Connect
- (void)requestProductsWithCompletionHandler:(RequestProductsCompletionHandler)completionHandler {
    
    // 1
    _completionHandler = [completionHandler copy];
    
    // 2
    _productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:_productIdentifiers];
    _productsRequest.delegate = self;
    [_productsRequest start];
    
}

#pragma mark - SKProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    
    NSLog(@"Loaded list of products...");
    _productsRequest = nil;
    
    NSArray * skProducts = response.products;
    for (SKProduct * skProduct in skProducts) {
        NSLog(@"Found product: %@ %@ %0.2f",
              skProduct.productIdentifier,
              skProduct.localizedTitle,
              skProduct.price.floatValue);
    }
    
    _completionHandler(YES, skProducts);
    _completionHandler = nil;
    
}
//Speaking of delegate callbacks, add those next!
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    
    NSLog(@"Failed to load list of products.");
    
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"isAppio"]){
        UIAlertView *badLoad=[[UIAlertView alloc] initWithTitle:@"No Products Found" message:@"Please check network connection and try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [badLoad show];
    }
    
    _productsRequest = nil;
    
    _completionHandler(NO, nil);
    _completionHandler = nil;
    
}
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction * transaction in transactions) {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
            default:
                break;
        }
    };
}

//implementing the completeTransaction, restoreTransaction, and failedTransaction methods.
- (void)completeTransaction:(SKPaymentTransaction *)transaction {
    NSLog(@"completeTransaction...");
    
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
    NSLog(@"restoreTransaction...");
    
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction {
    
    NSLog(@"failedTransaction...");
    if (transaction.error.code != SKErrorPaymentCancelled)
    {
        NSLog(@"Transaction error: %@", transaction.error.localizedDescription);
    }
    
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

- (void)provideContentForProductIdentifier:(NSString *)productIdentifier {
    
    [_purchasedProductIdentifiers addObject:productIdentifier];
    
    NSString *mystr = productIdentifier;
    NSString *lastLetters=[mystr substringFromIndex:[mystr length] -2];
        
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:productIdentifier];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[PFUser currentUser] setObject:[NSDate date] forKey:lastLetters];
    [[PFUser currentUser] saveInBackground];
        
    NSLog(@"Subscription Complete!");
    
    [[NSNotificationCenter defaultCenter] postNotificationName:IAPHelperProductPurchasedNotification object:productIdentifier userInfo:nil];
}

- (BOOL)restoreCompletedTransactionsForProducts:(NSArray *)products {
    
    if ([PFUser currentUser].isAuthenticated) {
        if(![PFAnonymousUtils isLinkedWithUser:[PFUser currentUser]]){
        
            PFQuery *query = [PFQuery queryWithClassName:@"_User"];
        
            [query getObjectInBackgroundWithId:[PFUser currentUser].objectId block:^(PFObject *object, NSError *error) {
    
                for (NSString *product in products){
                    
                    NSString *lastLetters=[product substringFromIndex:[product length] -2];
                
                    //retrieve the trueDate of purchase.
                    NSDate * trueDate = [object objectForKey:lastLetters];
                    //set the user defaults for each state
                    [[NSUserDefaults standardUserDefaults] setObject:trueDate forKey:product];
                    //Change settings for RI to today.
                    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"RedOstrich.CapitolBuddy.Universal.RI"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    
                    //Get the vote count file.
                    NSString *stateVotes= [NSString stringWithFormat:@"voteCountFile_%@",lastLetters];
                    PFFile *restoredVotes = [object objectForKey:stateVotes];
                    [restoredVotes getDataInBackgroundWithBlock:^(NSData *newVotesCrud, NSError *error){
                        if(newVotesCrud!=nil){
                            DataLoader *dbCrud =[[DataLoader alloc]init];
                            NSString *stateFile= [NSString stringWithFormat:@"SavedBills_%@.sqlite",lastLetters];
                            NSString *filePath=[dbCrud.GetDocumentDirectory stringByAppendingPathComponent:stateFile];
                            [newVotesCrud writeToFile:filePath atomically:YES];
                        }
                    }];
                    
                
                    //Get the notesFile
                    NSString *stateNotes= [NSString stringWithFormat:@"notesFile_%@",lastLetters];
                    PFFile *restoredNotes = [object objectForKey:stateNotes];
                    [restoredNotes getDataInBackgroundWithBlock:^(NSData *newNotesCrud, NSError *error){
                        if(newNotesCrud!=nil){
                            DataLoader *dbCrud =[[DataLoader alloc]init];
                            NSString *stateFile= [NSString stringWithFormat:@"%@.sqlite",lastLetters];
                            NSString *crudFileName = [@"crudDBNotes_" stringByAppendingString:stateFile];
                            NSString *filePath=[dbCrud.GetDocumentDirectory stringByAppendingPathComponent:crudFileName];
                            [newNotesCrud writeToFile:filePath atomically:YES];
                        }
                    }];
                    
                }
            }];
 

            
            NSLog(@"Restore Complete!");
            
            return YES;
        }
        else{
            UIAlertView *noUser=[[UIAlertView alloc] initWithTitle:@"Please log in first" message:@"You must log in to CapitolBuddy to restore your purchases. You are currently logged in anonymously." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [noUser show];

            return NO;
        }
    }
    else{
        UIAlertView *noUser=[[UIAlertView alloc] initWithTitle:@"Please log in first" message:@"You must log in to CapitolBuddy to restore your purchases." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [noUser show];
        return NO;
    }
}

- (int)daysRemainingOnSubscriptionForProduct:(NSString *)productIdentifier {
    //1
    NSDate *purchaseDate = [[NSUserDefaults standardUserDefaults]
                              objectForKey:productIdentifier];
    
    //2
    if (purchaseDate != 0){
        NSTimeInterval timeInt = [[self getExpirationDateForProduct:productIdentifier] timeIntervalSinceDate:purchaseDate];
    
    //3
        int days = timeInt / 60 / 60 / 24;
    
    //4
        if (days > 0) {
            //NSLog([NSString stringWithFormat:@"%d days remaining",days]);
            return days;
        }
        else {
            return 0;
        }
    }
    else {
            //NSLog([NSString stringWithFormat:@"There was no expiration date for %@",productIdentifier]);
            return 0;  
    }
}
- (NSDate *)getExpirationDateForProduct:(NSString *)productIdentifier {
    
    NSDate *originDate = [[NSUserDefaults standardUserDefaults]
                      objectForKey:productIdentifier];
        NSDateComponents *dateComp = [[NSDateComponents alloc] init];
        [dateComp setMonth:12];
        [dateComp setDay:0]; //add an extra day to subscription because we love our users
        
        
    NSDate * expirationDate =[[NSCalendar currentCalendar] dateByAddingComponents:dateComp
                                                             toDate:originDate
                                                            options:0];
    
    if (expirationDate>0) {
        return expirationDate;
    }
    else{
        return 0;
    }
    
}
- (NSString *)getExpirationDateStringForProduct: (NSString *)productIdentifier {
    if ([self daysRemainingOnSubscriptionForProduct:productIdentifier] > 0) {
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"MM/dd/yyyy"];
        return [NSString stringWithFormat:@"Subscribed! Expires: %@",[dateFormat stringFromDate:[self getExpirationDateForProduct:productIdentifier]]];
    }
    else {
        return @"Not Subscribed";
    }
}

@end