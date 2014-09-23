//
//  DataLoader.h
//  MOLegislature 3.0
//
//  Created by Paul Rolfe on 3/12/13.
//  Copyright (c) 2013 Paul Rolfe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "VoteTrackers.h"

@class VoteTrackers;

@interface DataLoader : NSObject {
    //legislatorsDB includes the committees. these variables are needed to load them. And create the cruds
    sqlite3 *cruddbLegs;
    sqlite3 *cruddbNotes;
    NSFileManager *fileMgr;
    NSString *homeDir;

}

@property (nonatomic,retain) NSString *homeDir;
@property (nonatomic,retain) NSFileManager *fileMgr;



//class methods
+ (DataLoader*)database;

//Instance methods

- (NSArray *)senators;
- (NSArray *)representatives;
- (NSArray *)committees;

- (NSArray *)savedBills;
-(void)InsertNewBill:(VoteTrackers *)bill;
-(void)UpdateSavedBills:(int)rowID :(NSArray *)_goodVotes :(NSArray *)_badVotes :(NSArray *)_swingVotes;
- (void)DeleteSavedBills:(int)rowID;

-(void)SenateUpdateRecords:(NSString *)txt :(NSString *)tyme :(int)sync :(int)utxt :(NSString *)rate;
-(void)HouseUpdateRecords:(NSString *)txt :(NSString *)tyme :(int)sync :(int)utxt :(NSString *)rate;
-(void)HouseUpdateBoolOnly:(int)sync :(int)utxt;
-(void)SenateUpdateBoolOnly:(int)sync :(int)utxt;
-(void)CopyDbToDocumentsFolder;
-(void)DownloadNewPhotos;
-(NSString *) GetDocumentDirectory;
//-(void) copyDataBaseIfNeeded;

-(void)copyStringsToDocumentsFolder;



@end