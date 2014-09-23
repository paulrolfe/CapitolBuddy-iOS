//
//  DataLoader.m
//  MOLegislature 3.0
//
//  Created by Paul Rolfe on 3/12/13.
//  Copyright (c) 2013 Paul Rolfe. All rights reserved.
//

#import "DataLoader.h"
#import "Legs.h"
#import "CommsClass.h"
#import "IAPHelper.h"
#import <Parse/Parse.h>
#import "AppDelegate.h"

@implementation DataLoader
@synthesize fileMgr,homeDir;

static DataLoader *_database;


-(NSString *)GetDocumentDirectory{
    fileMgr = [NSFileManager defaultManager];
    homeDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    
    return homeDir;
}


-(void)copyStringsToDocumentsFolder{
    NSURL *stringsURL = [NSURL URLWithString:@"https://s3.amazonaws.com/CapitolBuddy/StateList.strings"];
    NSData *stringsFile = [[NSData alloc] initWithContentsOfURL:stringsURL];
    NSString *filePath = [self.GetDocumentDirectory stringByAppendingPathComponent:@"IAPstrings"];
    
    if (stringsFile !=nil){
        [stringsFile writeToFile:filePath atomically:YES];
    }
}
-(void)CopyDbToDocumentsFolder{
    fileMgr = [NSFileManager defaultManager];
    
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    [defaults synchronize];
    
    NSString *currentState = [defaults objectForKey:@"state"];
    
    //download the state file from parse...
    PFQuery *query = [PFQuery queryWithClassName:@"States"];
    [query whereKey:@"state" equalTo:currentState];

    PFObject *stateObject = [query getFirstObject];
        
    PFFile *updatedStateDB = [stateObject objectForKey:@"download"];
    [updatedStateDB getDataInBackgroundWithBlock:^(NSData *newStateCrud, NSError *error){
                if(newStateCrud!=nil){
                    NSString *stateFileLocal= [currentState stringByAppendingString:@".sqlite"];
                    NSString *dbFileLocal = [@"crudDBLegs_" stringByAppendingString:stateFileLocal];
                    NSString *filePath = [self.GetDocumentDirectory stringByAppendingPathComponent:dbFileLocal];
                    [newStateCrud writeToFile:filePath atomically:YES];
                }
    }];
    
    if ([PFUser currentUser]){
        //Downlod the notes for the state you're looking at.
        PFQuery *queryNotes = [PFQuery queryWithClassName:@"_User"];
        
        [queryNotes getObjectInBackgroundWithId:[PFUser currentUser].objectId block:^(PFObject *object, NSError *error) {
            
            //Get the notesFile
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"kShouldDownloadNotes"]){
                //only download the stuff if the notes are up to date, aka YES for kShouldDownloadNotes.
                NSString *stateNotes= [NSString stringWithFormat:@"notesFile_%@",currentState];
                PFFile *restoredNotes = [object objectForKey:stateNotes];
                [restoredNotes getDataInBackgroundWithBlock:^(NSData *newNotesCrud, NSError *error){
                    if(newNotesCrud!=nil){
                        NSString *stateFile= [NSString stringWithFormat:@"%@.sqlite",currentState];
                        NSString *crudFileName = [@"crudDBNotes_" stringByAppendingString:stateFile];
                        NSString *filePath=[self.GetDocumentDirectory stringByAppendingPathComponent:crudFileName];
                        [newNotesCrud writeToFile:filePath atomically:YES];
                    }
                }];
            }
            
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"kShouldDownloadVotes"]){
                //only download the stuff if the notes are up to date, aka YES for kShouldDownloadVotes.
                //Get the vote count file.
                NSString *stateVotes= [NSString stringWithFormat:@"voteCountFile_%@",currentState];
                PFFile *restoredVotes = [object objectForKey:stateVotes];
                [restoredVotes getDataInBackgroundWithBlock:^(NSData *newVotesCrud, NSError *error){
                    if(newVotesCrud!=nil){
                        NSString *stateFile= [NSString stringWithFormat:@"SavedBills_%@.sqlite",currentState];
                        NSString *filePath=[self.GetDocumentDirectory stringByAppendingPathComponent:stateFile];
                        [newVotesCrud writeToFile:filePath atomically:YES];
                    }
                    else{
                        //Find the vote trackerfile online if it's a new state
                        NSData *dbFile3 = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:@"https://s3.amazonaws.com/CapitolBuddy/SavedBills.sqlite"]];
                        NSString *destFileName3 = [NSString stringWithFormat:@"SavedBills_%@.sqlite",[defaults objectForKey:@"state"]];
                        NSString *filePath3 = [self.GetDocumentDirectory stringByAppendingPathComponent:destFileName3];
                        
                        //check to see if there is db's have successfully loaded before.
                        if (![fileMgr fileExistsAtPath:filePath3]){
                            
                            //if there's no file already present and the notesDB isn't nil then it is copied to the documents.
                            if (dbFile3 != nil){
                                
                                [dbFile3 writeToFile:filePath3 atomically:YES];
                                
                            }
                        }
                    }
                }];
            }
        }];
    }
    
    //Find the notes file online if it's a new state.
    NSData *dbFile2 = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:@"https://s3.amazonaws.com/CapitolBuddy/NotesDB.sqlite"]];
    NSString *destFileName = [NSString stringWithFormat:@"crudDBNotes_%@.sqlite",[defaults objectForKey:@"state"]];
    NSString *filePath2 = [self.GetDocumentDirectory stringByAppendingPathComponent:destFileName];
    //check to see if the db's have successfully loaded before.
    if (![fileMgr fileExistsAtPath:filePath2]){
        //if there's no file already present and the notesDB isn't nil then it is copied to the documents.
        if (dbFile2 != nil){
            [dbFile2 writeToFile:filePath2 atomically:YES];
        }
    }

    
    //Copy the visited URL's file. (if none exists)
    NSString * fName = [[NSBundle mainBundle] pathForResource:@"VisitedURLs" ofType:@"strings"];
    NSData *data = [NSData dataWithContentsOfFile:fName];
    NSString *filePath4 = [self.GetDocumentDirectory stringByAppendingPathComponent:@"VisitedURLs.strings"];
    
    if (![fileMgr fileExistsAtPath:filePath4]){
        [data writeToFile:filePath4 atomically:YES];
    }
}
-(void) billsDBasFailSafe{
    NSData *dbFile3 = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:@"https://s3.amazonaws.com/CapitolBuddy/SavedBills.sqlite"]];
    NSString *destFileName3 = [NSString stringWithFormat:@"SavedBills_%@.sqlite",[[NSUserDefaults standardUserDefaults] objectForKey:@"state"]];
    NSString *filePath3 = [self.GetDocumentDirectory stringByAppendingPathComponent:destFileName3];
    //if there's no file already present and the notesDB isn't nil then it is copied to the documents.
    if (dbFile3 != nil){
        
        [dbFile3 writeToFile:filePath3 atomically:YES];
        
    }
}

//Some function that App Delegate calls.
 - (void)DownloadNewPhotos{
     
    //Download the state maps
     fileMgr = [NSFileManager defaultManager];
     
     NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
     [defaults synchronize];
     
     /*NSString *stateFile= [[defaults objectForKey:@"state"]stringByAppendingString:@".png"];
     NSString *houseFileName = [@"HouseMap_" stringByAppendingString:stateFile];
     NSString *senateFileName = [@"SenateMap_" stringByAppendingString:stateFile];
     
     NSString *housePngPath = [self.GetDocumentDirectory stringByAppendingPathComponent:houseFileName];
     NSString *senatePngPath = [self.GetDocumentDirectory stringByAppendingPathComponent:senateFileName];
     
     if (![fileMgr fileExistsAtPath:housePngPath]){
         NSURL *houseMapURL = [NSURL URLWithString:[@"https://s3.amazonaws.com/CapitolBuddy/maps/" stringByAppendingString:houseFileName]];
         NSData *pngFile = [[NSData alloc] initWithContentsOfURL:houseMapURL];
         if (pngFile!=nil){
         [pngFile writeToFile:housePngPath atomically:YES];
         }
         [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

     }
     if (![fileMgr fileExistsAtPath:senatePngPath]){
         NSURL *senateMapURL = [NSURL URLWithString:[@"https://s3.amazonaws.com/CapitolBuddy/maps/" stringByAppendingString:senateFileName]];
         NSData *pngFile = [[NSData alloc] initWithContentsOfURL:senateMapURL];
          if (pngFile!=nil){
         [pngFile writeToFile:senatePngPath atomically:YES];
          }
         [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

     }*/
     
     //Download the individual photos (if needed)
     //To change the image, upload it with a new file name such as RI_S5(2).jpg. Then change the file name in the DB. And it will now download RI_S5(2).jpg and the new DB will make it clear that it needs to use that image from the local directory.
     
     for (Legs * picIndex in self.senators /*each image file that exists*/){
         
         //copy to the pngPath if the pngPath file doesn't exist yet.
         NSString *pngName = picIndex.imageFile;
         NSString *pngPath = [self.GetDocumentDirectory stringByAppendingPathComponent:pngName];
    
         //don't copy if file exists.
         if(![fileMgr fileExistsAtPath:pngPath]){
             
             NSURL *URLfileName = [NSURL URLWithString:[@"https://s3.amazonaws.com/CapitolBuddy/headshots/" stringByAppendingString:pngName]];
             NSData *dbFile = [[NSData alloc] initWithContentsOfURL:URLfileName];
              if (dbFile!=nil){
             [dbFile writeToFile:pngPath atomically:YES];
              }
             [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
         }

         
     }
     
     for (Legs * picIndex in self.representatives /*each image file that exists*/){
         
         //copy to the pngPath if the pngPath file doesn't exist yet.
         NSString *pngName = picIndex.imageFile;
         NSString *pngPath = [self.GetDocumentDirectory stringByAppendingPathComponent:pngName];
         
         //don't copy if file exists.
         if(![fileMgr fileExistsAtPath:pngPath]){
             
             NSURL *URLfileName = [NSURL URLWithString:[@"https://s3.amazonaws.com/CapitolBuddy/headshots/" stringByAppendingString:pngName]];
             NSData *dbFile = [[NSData alloc] initWithContentsOfURL:URLfileName];
              if (dbFile!=nil){
             [dbFile writeToFile:pngPath atomically:YES];
              }
             [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
         }

     }
     //Stop the activity indicator
     [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];


}



+ (DataLoader*)database {
  
    _database = [[DataLoader alloc] init];
    
    return _database;
}
//create the senator arrays. This is called repeatedly, to refresh info sometimes. Because the notes and notesysnc info are loaded in this call as well.
- (NSArray *)senators{
    
    
    fileMgr = [NSFileManager defaultManager];
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    [defaults synchronize];
    
    NSMutableArray *retval= [[NSMutableArray alloc] init];
    int uniqueID;
    NSString *name;
    NSString *district;
    NSString *party;
    NSString *office;
    NSString *phone;
    NSString *email;
    NSString *website;
    NSString *staff;
    NSString *hometown;
    NSString *bio;
    NSString *HSType;
    NSString *comms;
    NSString *image;
    NSString *notes;
    NSString *timeStamp;
    int syncBool;
    NSString *rating;
    NSString *leadership;
    
    NSString *sql = @"Select rowID, Name, District, Party, Office, Phone, Email, Website, Staff, Hometown, Bio, Notes, HSType, Comms, ImageFile, NotesTimeStamp, NotesSync from sens";
    NSString *stateFileLocal= [[defaults objectForKey:@"state"]stringByAppendingString:@".sqlite"];
    NSString *dbFileLocal = [@"crudDBLegs_" stringByAppendingString:stateFileLocal];
    NSString *cruddatabase = [self.GetDocumentDirectory stringByAppendingPathComponent:dbFileLocal];
    
    //modify string so that DBcrudnotes file name is right.
    NSString *stateFile= [[defaults objectForKey:@"state"]stringByAppendingString:@".sqlite"];
    NSString *crudFileName = [@"crudDBNotes_" stringByAppendingString:stateFile];
    
    //sql stmnt to grab notes info.
    NSString *sql2 = @"Select rowID, Rating, Notes, HSType, NotesTimeStamp, NotesSync from SensNotes";
    NSString *cruddatabase2 = [self.GetDocumentDirectory stringByAppendingPathComponent:crudFileName];
    
    sqlite3_open([cruddatabase UTF8String], &cruddbLegs);
    sqlite3_open([cruddatabase2 UTF8String], &cruddbNotes);
    
    sqlite3_stmt *selectstmt;
    sqlite3_stmt *selectstmt2;
    sqlite3_prepare_v2(cruddbNotes, [sql2 UTF8String], -1, &selectstmt2, NULL);
    if(sqlite3_prepare_v2(cruddbLegs, [sql UTF8String], -1, &selectstmt, NULL) == SQLITE_OK)
    {
        
        while (sqlite3_step(selectstmt) == SQLITE_ROW) {
            
            //Getting the leg data
            uniqueID = sqlite3_column_int(selectstmt, 0);
            char *nameChars = (char *) sqlite3_column_text(selectstmt, 1);
            char *districtChars = (char *) sqlite3_column_text(selectstmt, 2);
            char *partyChars = (char *) sqlite3_column_text(selectstmt, 3);
            char *officeChars = (char *) sqlite3_column_text(selectstmt, 4);
            char *phoneChars = (char *) sqlite3_column_text(selectstmt, 5);
            char *emailChars = (char *) sqlite3_column_text(selectstmt, 6);
            char *websiteChars = (char *) sqlite3_column_text(selectstmt, 7);
            char *staffChars = (char *) sqlite3_column_text(selectstmt, 8);
            char *hometownChars = (char *) sqlite3_column_text(selectstmt, 9);
            char *bioChars = (char *) sqlite3_column_text(selectstmt, 10);
            char *leaderChars = (char *) sqlite3_column_text(selectstmt, 11);
            char *hstypeChars = (char *) sqlite3_column_text(selectstmt, 12);
            char *commsChars = (char *) sqlite3_column_text(selectstmt, 13);
            char *imageChars = (char *) sqlite3_column_text(selectstmt, 14);
            //char *timestampChars = (char *) sqlite3_column_text(selectstmt, 15);
            //int syncInt = sqlite3_column_int(selectstmt, 16);
            
            name = [[NSString alloc] initWithUTF8String:nameChars];
            district = [[NSString alloc] initWithUTF8String:districtChars];
            party = [[NSString alloc] initWithUTF8String:partyChars];
            office = [[NSString alloc] initWithUTF8String:officeChars];
            phone = [[NSString alloc] initWithUTF8String:phoneChars];
            email = [[NSString alloc] initWithUTF8String:emailChars];
            website = [[NSString alloc] initWithUTF8String:websiteChars];
            staff = [[NSString alloc] initWithUTF8String:staffChars];
            hometown = [[NSString alloc] initWithUTF8String:hometownChars];
            bio = [[NSString alloc] initWithUTF8String:bioChars];
            leadership = [[NSString alloc] initWithUTF8String:leaderChars];
            HSType = [[NSString alloc] initWithUTF8String:hstypeChars];
            comms = [[NSString alloc] initWithUTF8String:commsChars];
            image = [[NSString alloc] initWithUTF8String:imageChars];
            //NSString *timeStamp = [[NSString alloc] initWithUTF8String:timestampChars];
            //int syncBool=syncInt;
            
            
            
            
            sqlite3_step(selectstmt2);
                    
                    //Getting the notes data.
                    char *notesChars = (char *) sqlite3_column_text(selectstmt2, 2);
                    char *timestampChars = (char *) sqlite3_column_text(selectstmt2, 4);
                    int syncInt = sqlite3_column_int(selectstmt2, 5);
                    char *ratingChars = (char *) sqlite3_column_text(selectstmt2, 1);
            
                    
                    notes = [[NSString alloc] initWithUTF8String:notesChars];
                    timeStamp = [[NSString alloc] initWithUTF8String:timestampChars];
                    syncBool=syncInt;
                    rating=[[NSString alloc] initWithUTF8String:ratingChars];
                    
            Legs *info = [[Legs alloc]initWithUniqueId:uniqueID name:name district:district party:party office:office phone:phone email:email website:website staff:staff hometown:hometown bio:bio notes:notes hstype:HSType comms:comms imageFile:image timeStamp:timeStamp syncBool:syncBool rating:rating leadership:leadership];
                    [retval addObject:info];
        }
    }
    sqlite3_finalize(selectstmt);
    sqlite3_finalize(selectstmt2);
    sqlite3_close(cruddbLegs);
    sqlite3_close(cruddbNotes);
    
    return retval;
}
//same for reps.
- (NSArray *)representatives{
    
    fileMgr = [NSFileManager defaultManager];
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    [defaults synchronize];
    
    NSMutableArray *retval= [[NSMutableArray alloc] init];
    int uniqueID;
    NSString *name;
    NSString *district;
    NSString *party;
    NSString *office;
    NSString *phone;
    NSString *email;
    NSString *website;
    NSString *staff;
    NSString *hometown;
    NSString *bio;
    NSString *HSType;
    NSString *comms;
    NSString *image;
    NSString *notes;
    NSString *timeStamp;
    int syncBool;
    NSString *rating;
    NSString *leadership;
    
    NSString *sql = @"Select rowID, Name, District, Party, Office, Phone, Email, Website, Staff, Hometown, Bio, Notes, HSType, Comms, ImageFile, NotesTimeStamp, NotesSync from reps";
    
    NSString *stateFileLocal= [[defaults objectForKey:@"state"]stringByAppendingString:@".sqlite"];
    NSString *dbFileLocal = [@"crudDBLegs_" stringByAppendingString:stateFileLocal];
    NSString *cruddatabase = [self.GetDocumentDirectory stringByAppendingPathComponent:dbFileLocal];
    
    //modify string so that DBcrudnotes file name is right.
    NSString *stateFile= [[defaults objectForKey:@"state"]stringByAppendingString:@".sqlite"];
    NSString *crudFileName = [@"crudDBNotes_" stringByAppendingString:stateFile];
    
    //sql stmnt to grab notes info.
    NSString *sql2 = @"Select rowID, Rating, Notes, HSType, NotesTimeStamp, NotesSync from RepsNotes";
    NSString *cruddatabase2 = [self.GetDocumentDirectory stringByAppendingPathComponent:crudFileName];
    
    sqlite3_open([cruddatabase UTF8String], &cruddbLegs);
    sqlite3_open([cruddatabase2 UTF8String], &cruddbNotes);
    
    sqlite3_stmt *selectstmt;
    sqlite3_stmt *selectstmt2;
    sqlite3_prepare_v2(cruddbNotes, [sql2 UTF8String], -1, &selectstmt2, NULL);
    if(sqlite3_prepare_v2(cruddbLegs, [sql UTF8String], -1, &selectstmt, NULL) == SQLITE_OK)
    {
        
        while (sqlite3_step(selectstmt) == SQLITE_ROW) {
            
            uniqueID = sqlite3_column_int(selectstmt, 0);
            char *nameChars = (char *) sqlite3_column_text(selectstmt, 1);
            char *districtChars = (char *) sqlite3_column_text(selectstmt, 2);
            char *partyChars = (char *) sqlite3_column_text(selectstmt, 3);
            char *officeChars = (char *) sqlite3_column_text(selectstmt, 4);
            char *phoneChars = (char *) sqlite3_column_text(selectstmt, 5);
            char *emailChars = (char *) sqlite3_column_text(selectstmt, 6);
            char *websiteChars = (char *) sqlite3_column_text(selectstmt, 7);
            char *staffChars = (char *) sqlite3_column_text(selectstmt, 8);
            char *hometownChars = (char *) sqlite3_column_text(selectstmt, 9);
            char *bioChars = (char *) sqlite3_column_text(selectstmt, 10);
            char *leaderChars = (char *) sqlite3_column_text(selectstmt, 11);
            char *hstypeChars = (char *) sqlite3_column_text(selectstmt, 12);
            char *commsChars = (char *) sqlite3_column_text(selectstmt, 13);
            char *imageChars = (char *) sqlite3_column_text(selectstmt, 14);
            
            name = [[NSString alloc] initWithUTF8String:nameChars];
            district = [[NSString alloc] initWithUTF8String:districtChars];
            party = [[NSString alloc] initWithUTF8String:partyChars];
            office = [[NSString alloc] initWithUTF8String:officeChars];
            phone = [[NSString alloc] initWithUTF8String:phoneChars];
            email = [[NSString alloc] initWithUTF8String:emailChars];
            website = [[NSString alloc] initWithUTF8String:websiteChars];
            staff = [[NSString alloc] initWithUTF8String:staffChars];
            hometown = [[NSString alloc] initWithUTF8String:hometownChars];
            bio = [[NSString alloc] initWithUTF8String:bioChars];
            leadership = [[NSString alloc] initWithUTF8String:leaderChars];
            HSType = [[NSString alloc] initWithUTF8String:hstypeChars];
            comms = [[NSString alloc] initWithUTF8String:commsChars];
            image = [[NSString alloc] initWithUTF8String:imageChars];
            
            
            
            
            sqlite3_step(selectstmt2);
            
            //Getting the notes data.
            char *notesChars = (char *) sqlite3_column_text(selectstmt2, 2);
            char *timestampChars = (char *) sqlite3_column_text(selectstmt2, 4);
            int syncInt = sqlite3_column_int(selectstmt2, 5);
            char *ratingChars = (char *) sqlite3_column_text(selectstmt2, 1);
            
            
            notes = [[NSString alloc] initWithUTF8String:notesChars];
            timeStamp = [[NSString alloc] initWithUTF8String:timestampChars];
            syncBool=syncInt;
            rating=[[NSString alloc] initWithUTF8String:ratingChars];
            
            Legs *info = [[Legs alloc]initWithUniqueId:uniqueID name:name district:district party:party office:office phone:phone email:email website:website staff:staff hometown:hometown bio:bio notes:notes hstype:HSType comms:comms imageFile:image timeStamp:timeStamp syncBool:syncBool rating:rating leadership:leadership];
            [retval addObject:info];
        }
    }
    sqlite3_finalize(selectstmt);
    sqlite3_finalize(selectstmt2);
    sqlite3_close(cruddbLegs);
    sqlite3_close(cruddbNotes);
    
    return retval;
}
- (NSArray *)committees{
    
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    [defaults synchronize];
    
    NSString *sql = @"Select rowID, HSType, CommName, URL from CommURLs";
    
    NSString *stateFileLocal= [[defaults objectForKey:@"state"]stringByAppendingString:@".sqlite"];
    NSString *dbFileLocal = [@"crudDBLegs_" stringByAppendingString:stateFileLocal];
    NSString *cruddatabase = [self.GetDocumentDirectory stringByAppendingPathComponent:dbFileLocal];
    
    sqlite3_open([cruddatabase UTF8String], &cruddbLegs);
    sqlite3_stmt *selectstmt;
    if(sqlite3_prepare_v2(cruddbLegs, [sql UTF8String], -1, &selectstmt, NULL) == SQLITE_OK)
    {
        
        while (sqlite3_step(selectstmt) == SQLITE_ROW) {
            
            int uniqueID = sqlite3_column_int(selectstmt, 0);
            char *hstypeChars = (char *) sqlite3_column_text(selectstmt, 1);
            char *commNameChars = (char *) sqlite3_column_text(selectstmt, 2);
            char *commURLChars = (char *) sqlite3_column_text(selectstmt, 3);
            
            NSString *hsType = [[NSString alloc] initWithUTF8String:hstypeChars];
            NSString *commName = [[NSString alloc] initWithUTF8String:commNameChars];
            NSString *commURL = [[NSString alloc] initWithUTF8String:commURLChars];
            
            
            CommsClass *info = [[CommsClass alloc] initWithUniqueId:uniqueID hsType:hsType commName:commName commURL:commURL];
            [retval addObject:info];
        }
        sqlite3_finalize(selectstmt);
    }
    return retval;
}

- (NSArray *)savedBills{
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    [defaults synchronize];
    
    NSString *sql = @"Select rowID, BillName, Bill_hsType, GoodVotes, BadVotes, SwingVotes, TargetState from tracking";
    
    NSString *dbFileLocal = [NSString stringWithFormat:@"SavedBills_%@.sqlite",[defaults objectForKey:@"state"]];
    NSString *cruddatabase = [self.GetDocumentDirectory stringByAppendingPathComponent:dbFileLocal];
    
    sqlite3_open([cruddatabase UTF8String], &cruddbLegs);
    sqlite3_stmt *selectstmt;
    if(sqlite3_prepare_v2(cruddbLegs, [sql UTF8String], -1, &selectstmt, NULL) == SQLITE_OK)
    {
        
        while (sqlite3_step(selectstmt) == SQLITE_ROW) {
            
            int uniqueID = sqlite3_column_int(selectstmt, 0);
            char *BillName = (char *) sqlite3_column_text(selectstmt, 1);
            char *bill_hsType = (char *) sqlite3_column_text(selectstmt, 2);
            char *goodVotesBytes= (char *) sqlite3_column_text(selectstmt, 3);
            char *badVotesBytes= (char *) sqlite3_column_text(selectstmt, 4);
            char *swingVotesBytes= (char *) sqlite3_column_text(selectstmt, 5);
            char *TargetState=(char *) sqlite3_column_text(selectstmt, 6);
            
            NSString *billName = [[NSString alloc] initWithUTF8String:BillName];
            NSString *billHStype = [[NSString alloc] initWithUTF8String:bill_hsType];
            NSString * goodVotesString= [[NSString alloc] initWithUTF8String:goodVotesBytes];
            NSString * badVotesString= [[NSString alloc] initWithUTF8String:badVotesBytes];
            NSString * swingVotesString= [[NSString alloc] initWithUTF8String:swingVotesBytes];
            NSString * targetState= [[NSString alloc] initWithUTF8String:TargetState];
            
            //Make the strings into Arrays
            NSArray *goodVotesArray = [goodVotesString componentsSeparatedByString:@","];
             NSArray *badVotesArray = [badVotesString componentsSeparatedByString:@","];
             NSArray *swingVotesArray = [swingVotesString componentsSeparatedByString:@","];
            
            VoteTrackers *info = [[VoteTrackers alloc]initWithUniqueId:uniqueID billName:billName billHStype:billHStype goodVotes:goodVotesArray badVotes:badVotesArray swingVotes:swingVotesArray targetState:targetState];
            [retval addObject:info];
        }
        sqlite3_finalize(selectstmt);
    }
    return retval;
}
-(void)InsertNewBill:(VoteTrackers *)bill{
    
    sqlite3_stmt *insertstmt;
    
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    [defaults synchronize];
    
    NSString *dbFileLocal = [NSString stringWithFormat:@"SavedBills_%@.sqlite",[defaults objectForKey:@"state"]];
    NSString *cruddatabase = [self.GetDocumentDirectory stringByAppendingPathComponent:dbFileLocal];
    
    //Make the NSArrays into strings
    
    NSString *gVotes = [bill.goodVotes componentsJoinedByString:@","];
    NSString *bVotes =[bill.badVotes componentsJoinedByString:@","];
    NSString *sVotes =[bill.swingVotes componentsJoinedByString:@","];
    
    
    if(sqlite3_open([cruddatabase UTF8String], &cruddbNotes) == SQLITE_OK)
    {
        //sql stmnt to grab notes info.
        NSString *sqlquery = @"INSERT into tracking (rowID, BillName, Bill_hsType, GoodVotes, BadVotes, SwingVotes, TargetState) VALUES (?,?,?,?,?,?,?)";
        
        const char*sql=[sqlquery UTF8String];
        if(sqlite3_prepare_v2(cruddbNotes,sql, -1, &insertstmt, NULL) == SQLITE_OK){
            sqlite3_bind_int(insertstmt, 1, bill.uniqueRowID);
            sqlite3_bind_text(insertstmt, 2, [bill.billName UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(insertstmt, 3, [bill.billHStype UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(insertstmt, 4, [gVotes UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(insertstmt, 5, [bVotes UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(insertstmt, 6, [sVotes UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(insertstmt, 7, [bill.targetState UTF8String], -1, SQLITE_TRANSIENT);
            
            if(SQLITE_DONE != sqlite3_step(insertstmt))
            {
                NSAssert1(0, @"Error while inserting. '%s'", sqlite3_errmsg(cruddbNotes));
            }
            else{
                sqlite3_reset(insertstmt);
                NSLog(@"Insert done successfully at row %d",bill.uniqueRowID);
            }
        }
        else{
            [self billsDBasFailSafe];
            [self InsertNewBill:bill];
        }
        
        
        sqlite3_finalize(insertstmt);
    }

    sqlite3_close(cruddbNotes);
}
- (void)DeleteSavedBills:(int)rowID{
    sqlite3_stmt *updatestmt;
    
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    [defaults synchronize];
    
    NSString *dbFileLocal = [NSString stringWithFormat:@"SavedBills_%@.sqlite",[defaults objectForKey:@"state"]];
    NSString *cruddatabase = [self.GetDocumentDirectory stringByAppendingPathComponent:dbFileLocal];
    
    
    if(sqlite3_open([cruddatabase UTF8String], &cruddbNotes) == SQLITE_OK)
    {
        //sql stmnt to grab notes info.
        NSString *sqlquery = @"DELETE from tracking WHERE rowID=?";
        
        const char*sql=[sqlquery UTF8String];
        if(sqlite3_prepare_v2(cruddbNotes,sql, -1, &updatestmt, NULL) == SQLITE_OK){
            sqlite3_bind_int(updatestmt, 1, rowID);

            if(SQLITE_DONE != sqlite3_step(updatestmt))
            {
                NSAssert1(0, @"Error while updating. '%s'", sqlite3_errmsg(cruddbNotes));
            }
            else{
                sqlite3_reset(updatestmt);
                NSLog(@"Delete done successfully on row %d",rowID);
            }
        }
 
        
        sqlite3_finalize(updatestmt);
    }
    sqlite3_close(cruddbNotes);
    
    
    

}

-(void)UpdateSavedBills:(int)rowID :(NSArray *)_goodVotes :(NSArray *)_badVotes :(NSArray *)_swingVotes
{
    sqlite3_stmt *updatestmt;
    
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    [defaults synchronize];
    
    NSString *dbFileLocal = [NSString stringWithFormat:@"SavedBills_%@.sqlite",[defaults objectForKey:@"state"]];
    NSString *cruddatabase = [self.GetDocumentDirectory stringByAppendingPathComponent:dbFileLocal];
    
    //Make the NSArrays into strings
    
    NSString *gVotes = [_goodVotes componentsJoinedByString:@","];
    NSString *bVotes =[_badVotes componentsJoinedByString:@","];
    NSString *sVotes =[_swingVotes componentsJoinedByString:@","];
    
    
    if(sqlite3_open([cruddatabase UTF8String], &cruddbNotes) == SQLITE_OK)
    {
        //sql stmnt to grab notes info.
        NSString *sqlquery = @"UPDATE tracking SET GoodVotes=?, BadVotes=?, SwingVotes=? WHERE rowID=?";
        
        const char*sql=[sqlquery UTF8String];
        if(sqlite3_prepare_v2(cruddbNotes,sql, -1, &updatestmt, NULL) == SQLITE_OK){
            sqlite3_bind_text(updatestmt, 1, [gVotes UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(updatestmt, 2, [bVotes UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(updatestmt, 3, [sVotes UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(updatestmt, 4, rowID);
            if(SQLITE_DONE != sqlite3_step(updatestmt))
            {
                NSAssert1(0, @"Error while updating. '%s'", sqlite3_errmsg(cruddbNotes));
            }
            else{
                sqlite3_reset(updatestmt);
                NSLog(@"Update done successfully!");
            }
        }
        
        
        
        sqlite3_finalize(updatestmt);
    }
    sqlite3_close(cruddbNotes);
    
    
    
}


-(void)SenateUpdateRecords:(NSString *)txt :(NSString *)tyme :(int)sync :(int)utxt :(NSString *)rate{
    sqlite3_stmt *updatestmt;
    
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    [defaults synchronize];
    
    NSString *stateFile= [[defaults objectForKey:@"state"]stringByAppendingString:@".sqlite"];
    NSString *crudFileName = [@"crudDBNotes_" stringByAppendingString:stateFile];
    
    NSString *cruddatabase = [self.GetDocumentDirectory stringByAppendingPathComponent:crudFileName];
    
    
    if(sqlite3_open([cruddatabase UTF8String], &cruddbNotes) == SQLITE_OK)
    {
        //sql stmnt to grab notes info.
        NSString *sqlquery = @"UPDATE SensNotes SET Notes=?, NotesTimeStamp=?, NotesSync=?, Rating=? WHERE rowID=?";
        
        //NSString *sqlquery = @"UPDATE MoSensNotes SET Notes=?, NotesTimeStamp=?, NotesSync=? WHERE rowID=?";
        const char*sql=[sqlquery UTF8String];
        if(sqlite3_prepare_v2(cruddbNotes,sql, -1, &updatestmt, NULL) == SQLITE_OK){
            sqlite3_bind_text(updatestmt, 1, [txt UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(updatestmt, 2, [tyme UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(updatestmt, 3, sync);
            sqlite3_bind_text(updatestmt, 4, [rate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(updatestmt, 5, utxt);
            if(SQLITE_DONE != sqlite3_step(updatestmt))
            {
                NSAssert1(0, @"Error while updating. '%s'", sqlite3_errmsg(cruddbNotes));
            }
            else{
                sqlite3_reset(updatestmt);
                NSLog(@"Update done successfully!");
            }
        }
        
        
        
        sqlite3_finalize(updatestmt);
    }
    sqlite3_close(cruddbNotes);



}
-(void)HouseUpdateRecords:(NSString *)txt :(NSString *)tyme :(int)sync :(int)utxt :(NSString *)rate{
    sqlite3_stmt *updatestmt;
    
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    [defaults synchronize];
    
    NSString *stateFile= [[defaults objectForKey:@"state"]stringByAppendingString:@".sqlite"];
    NSString *crudFileName = [@"crudDBNotes_" stringByAppendingString:stateFile];
    
    NSString *cruddatabase = [self.GetDocumentDirectory stringByAppendingPathComponent:crudFileName];
    
    
    if(sqlite3_open([cruddatabase UTF8String], &cruddbNotes) == SQLITE_OK)
    {
        //sql stmnt to grab notes info.
        NSString *sqlquery = @"UPDATE RepsNotes SET Notes=?, NotesTimeStamp=?, NotesSync=?, Rating=? WHERE rowID=?";
        
        //NSString *sqlquery = @"UPDATE MoSensNotes SET Notes=?, NotesTimeStamp=?, NotesSync=? WHERE rowID=?";
        const char*sql=[sqlquery UTF8String];
        if(sqlite3_prepare_v2(cruddbNotes,sql, -1, &updatestmt, NULL) == SQLITE_OK){
            sqlite3_bind_text(updatestmt, 1, [txt UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(updatestmt, 2, [tyme UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(updatestmt, 3, sync);
            sqlite3_bind_text(updatestmt, 4, [rate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(updatestmt, 5, utxt);
            if(SQLITE_DONE != sqlite3_step(updatestmt))
            {
                NSAssert1(0, @"Error while updating. '%s'", sqlite3_errmsg(cruddbNotes));
            }
            else{
                sqlite3_reset(updatestmt);
                NSLog(@"Update done successfully!");
            }
        }
        
        
        
        sqlite3_finalize(updatestmt);
    }
    sqlite3_close(cruddbNotes);
    
    
    
}
-(void)HouseUpdateBoolOnly:(int)sync :(int)utxt{
    sqlite3_stmt *updatestmt;
    
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    [defaults synchronize];
    
    NSString *stateFile= [[defaults objectForKey:@"state"]stringByAppendingString:@".sqlite"];
    NSString *crudFileName = [@"crudDBNotes_" stringByAppendingString:stateFile];
    
    NSString *cruddatabase = [self.GetDocumentDirectory stringByAppendingPathComponent:crudFileName];
    
    if(sqlite3_open([cruddatabase UTF8String], &cruddbNotes) == SQLITE_OK)
    {
        
        //sql stmnt to grab notes info.
        NSString *sqlquery = @"UPDATE RepsNotes SET NotesSync=? WHERE rowID=?";
        
        //NSString *sqlquery = @"UPDATE MoRepsNotes SET NotesSync=? WHERE rowID=?";
        const char*sql=[sqlquery UTF8String];
        if(sqlite3_prepare_v2(cruddbNotes,sql, -1, &updatestmt, NULL) == SQLITE_OK){
            sqlite3_bind_int(updatestmt, 1, sync);
            sqlite3_bind_int(updatestmt, 2, utxt);
            if(SQLITE_DONE != sqlite3_step(updatestmt))
            {
                NSAssert1(0, @"Error while updating. '%s'", sqlite3_errmsg(cruddbNotes));
            }
            else{
                sqlite3_reset(updatestmt);
                NSLog(@"Update done successfully!");
            }
        }
        
        
        
        sqlite3_finalize(updatestmt);
    }
    sqlite3_close(cruddbNotes);
}
-(void)SenateUpdateBoolOnly:(int)sync :(int)utxt{
    sqlite3_stmt *updatestmt;
    
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    [defaults synchronize];
    
    NSString *stateFile= [[defaults objectForKey:@"state"]stringByAppendingString:@".sqlite"];
    NSString *crudFileName = [@"crudDBNotes_" stringByAppendingString:stateFile];
    
    NSString *cruddatabase = [self.GetDocumentDirectory stringByAppendingPathComponent:crudFileName];
    
    if(sqlite3_open([cruddatabase UTF8String], &cruddbNotes) == SQLITE_OK)
    {
        //sql stmnt to grab notes info.
        NSString *sqlquery = @"UPDATE SensNotes SET NotesSync=? WHERE rowID=?";
        
        //NSString *sqlquery = @"UPDATE MoSensNotes SET NotesSync=? WHERE rowID=?";
        const char*sql=[sqlquery UTF8String];
        if(sqlite3_prepare_v2(cruddbNotes,sql, -1, &updatestmt, NULL) == SQLITE_OK){
            sqlite3_bind_int(updatestmt, 1, sync);
            sqlite3_bind_int(updatestmt, 2, utxt);
            if(SQLITE_DONE != sqlite3_step(updatestmt))
            {
                NSAssert1(0, @"Error while updating. '%s'", sqlite3_errmsg(cruddbNotes));
            }
            else{
                sqlite3_reset(updatestmt);
                NSLog(@"Update done successfully!");
            }
        }
        
        
        
        sqlite3_finalize(updatestmt);
    }
    sqlite3_close(cruddbNotes);
}

@end

