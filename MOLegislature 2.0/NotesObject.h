//
//  NotesObject.h
//  CapitolBuddy
//
//  Created by Paul Rolfe on 1/19/14.
//  Copyright (c) 2014 Paul Rolfe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>
#import "Legs.h"

@interface NotesObject : NSObject{
    NSArray * allRoles;
}

//properties of a note
@property NSString * noteText;
@property NSString * timestamp;
@property NSString * objectIDParse;
@property NSArray * legTags;
@property PFACL * sharingSettings;
@property BOOL isEditable;
@property NSDate * updatedDate;
@property NSMutableArray * writeAccess;
@property NSMutableArray * readAccess;
@property PFUser * owner;
@property BOOL isNew; //for knowing if shared note has been seen or not
@property PFObject * pfObject;
@property BOOL  upVoted;
@property BOOL  downVoted;
@property BOOL  flagged;
@property BOOL isPublic;
@property NSInteger upCount;
@property NSInteger downCount;

- (id) initWithPFObject:(PFObject *)object;
- (NSString *) createLegIDforLeg:(Legs *)legislator;
-(NSString *) timeSinceLastSave;
-(NSString *) timeSinceShared;


- (NSMutableArray *) findMyNotesForLeg:(Legs *)legID withCachePolicy:(PFCachePolicy)cachePolicy;
- (NSMutableArray *) findAllMyNotesWithCachePolicy:(PFCachePolicy)cachePolicy skip:(NSInteger)skip;
- (NSMutableArray *) findNewNotesFromAlertsAndSetRead:(BOOL)readBool;
- (BOOL) findIfArray:(NSArray *)array ContainsNoteObject:(NotesObject *)object;

-(BOOL) findIfEditableForObject:(PFObject *)object;

- (NotesObject *) noteFromLeg: (Legs *)legID;
- (NotesObject *) makeNewNote: (Legs *)legID;
- (void) saveNote;
- (void) deleteNote;

@end

@interface UserObject : NSObject

@property NSData * imageData;
@property NSString * username;
@property NSString * realName;
@property NSString * realOrg;
@property NSString * email;
@property PFObject * userObject;
@property BOOL isPFRole;

@end