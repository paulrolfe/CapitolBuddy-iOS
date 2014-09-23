//
//  NotesObject.m
//  CapitolBuddy
//
//  Created by Paul Rolfe on 1/19/14.
//  Copyright (c) 2014 Paul Rolfe. All rights reserved.
//

#import "NotesObject.h"

@implementation NotesObject

@synthesize noteText,timestamp,objectIDParse,legTags,sharingSettings,isEditable,updatedDate;
@synthesize readAccess,writeAccess,owner,isNew;
@synthesize upVoted,downVoted,flagged,isPublic;

- (id) initWithPFObject:(PFObject *)object{
    //self = [super init];
    if(self){
        [object fetchIfNeeded];
        self.legTags=object[@"legTags"];
        self.noteText=object[@"noteText"];
        self.timestamp=object[@"timeStamp"];
        self.sharingSettings=object.ACL;
        self.objectIDParse=object.objectId;
        self.updatedDate=object[@"savedDate"];
        self.isEditable=[self findIfEditableForObject:object];
        self.writeAccess=object[@"writeAccess"];
        self.readAccess=object[@"readAccess"];
        self.owner=object[@"owner"];
        self.pfObject=object;
        //public stuff
        self.upVoted=[(NSArray *)object[@"upVotes"] containsObject:[PFUser currentUser].objectId];
        self.downVoted=[(NSArray *)object[@"downVotes"] containsObject:[PFUser currentUser].objectId];
        self.flagged=[(NSArray *)object[@"flagged"] containsObject:[PFUser currentUser].objectId];
        self.isPublic=[object.ACL getPublicReadAccess];
        self.upCount=((NSArray *)object[@"upVotes"]).count;
        self.downCount=((NSArray *)object[@"downVotes"]).count;
    }
    return self;
}

//converts legislator's custom info into a viewable note object.
- (id) noteFromLeg: (Legs *)legID{
    
    self.noteText = legID.notes;
    self.isEditable=YES;
    self.timestamp=legID.timeStamp;
    self.objectIDParse = @"private";
    self.legTags = @[[self createLegIDforLeg:legID]];
    self.sharingSettings=[PFACL ACLWithUser:[PFUser currentUser]];
    
    return self;
}
//creates a new note with a tag for this leg object.
- (id) makeNewNote: (Legs *)legID{
    
    self.noteText = @"";
    self.isEditable=YES;
    self.timestamp=@"Never";
    self.objectIDParse = @"newnote";
    //if blank, set no legtags
    if (legID)
        self.legTags = @[[self createLegIDforLeg:legID]];
    //just set a blank array.
    else
        self.legTags = @[];
    self.sharingSettings=[PFACL ACLWithUser:[PFUser currentUser]];
    self.writeAccess = [[NSMutableArray alloc]initWithObjects:[PFUser currentUser], nil];
    self.owner = [PFUser currentUser];
    return self;
}

//load notes for views coming from legislators
- (NSMutableArray *) findMyNotesForLeg:(Legs *)legID withCachePolicy:(PFCachePolicy)cachePolicy{
    //should return the notes for this legID where current user has read access.
    PFQuery * roleQuery = [PFRole query];
    roleQuery.cachePolicy=cachePolicy;
    [roleQuery whereKey:@"users" equalTo:[PFUser currentUser]];
    allRoles=[roleQuery findObjects];
    
    
    NSMutableArray * notesArray = [[NSMutableArray alloc]init]; //an array of NoteObjects that correspond to this legislator.
    PFQuery * query = [PFQuery queryWithClassName:@"Notes"];
    query.cachePolicy=cachePolicy;
    [query whereKey:@"legTags" equalTo:[self createLegIDforLeg:legID]];
    NSArray * objects = [query findObjects];//[query findObjectsInBackgroundWithBlock:^(NSArray * objects, NSError * error){
    
    for(PFObject * object in objects){
        NotesObject * noteObject = [[NotesObject alloc] init];
        noteObject.legTags=object[@"legTags"];
        noteObject.noteText=object[@"noteText"];
        noteObject.timestamp=object[@"timeStamp"];
        noteObject.sharingSettings=object.ACL;
        noteObject.objectIDParse=object.objectId;
        noteObject.updatedDate=object[@"savedDate"];
        noteObject.isEditable=[self findIfEditableForObject:object];
        noteObject.writeAccess=object[@"writeAccess"];
        noteObject.readAccess=object[@"readAccess"];
        noteObject.owner=object[@"owner"];
        noteObject.pfObject=object;
        //public stuff
        noteObject.upVoted=[(NSArray *)object[@"upVotes"] containsObject:[PFUser currentUser].objectId];
        noteObject.downVoted=[(NSArray *)object[@"downVotes"] containsObject:[PFUser currentUser].objectId];
        noteObject.flagged=[(NSArray *)object[@"flagged"] containsObject:[PFUser currentUser].objectId];
        noteObject.isPublic=[object.ACL getPublicReadAccess];
        noteObject.upCount=((NSArray *)object[@"upVotes"]).count;
        noteObject.downCount=((NSArray *)object[@"downVotes"]).count;
        [notesArray addObject:noteObject];
    }
    //}];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"updatedDate" ascending:NO];
    [notesArray sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    return notesArray;
}
//load notes for note feed. Must be called in background thread.
- (NSMutableArray *) findAllMyNotesWithCachePolicy:(PFCachePolicy)cachePolicy skip:(NSInteger)skip{
    PFQuery * roleQuery = [PFRole query];
    roleQuery.cachePolicy=cachePolicy;
    [roleQuery whereKey:@"users" equalTo:[PFUser currentUser]];
    allRoles=[roleQuery findObjects];
    
    NSMutableArray * notesArray = [[NSMutableArray alloc]init]; //an array of NoteObjects that are viewable by user.
    PFQuery * query = [PFQuery queryWithClassName:@"Notes"];
    query.cachePolicy=cachePolicy;
    [query orderByDescending:@"savedDate"];
    [query whereKey:@"state" equalTo:[[NSUserDefaults standardUserDefaults]objectForKey:@"state"]];
    query.skip=skip;
    NSArray * objects = [query findObjects];
    for(PFObject * object in objects){
        NotesObject * noteObject = [[NotesObject alloc] init];
        noteObject.legTags=object[@"legTags"];
        noteObject.noteText=object[@"noteText"];
        noteObject.timestamp=object[@"timeStamp"];
        noteObject.sharingSettings=object.ACL;
        noteObject.objectIDParse=object.objectId;
        noteObject.updatedDate=object[@"savedDate"];
        noteObject.isEditable=[self findIfEditableForObject:object];
        noteObject.writeAccess=object[@"writeAccess"];
        noteObject.readAccess=object[@"readAccess"];
        noteObject.owner=object[@"owner"];
        noteObject.pfObject=object;
        //public stuff
        noteObject.upVoted=[(NSArray *)object[@"upVotes"] containsObject:[PFUser currentUser].objectId];
        noteObject.downVoted=[(NSArray *)object[@"downVotes"] containsObject:[PFUser currentUser].objectId];
        noteObject.flagged=[(NSArray *)object[@"flagged"] containsObject:[PFUser currentUser].objectId];
        noteObject.isPublic=[object.ACL getPublicReadAccess];
        noteObject.upCount=((NSArray *)object[@"upVotes"]).count;
        noteObject.downCount=((NSArray *)object[@"downVotes"]).count;
        [notesArray addObject:noteObject];
    }
    /*
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"updatedDate" ascending:NO];
    [notesArray sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];*/
    
    return notesArray;
}
//load note share alerts for note feed
- (NSMutableArray *) findNewNotesFromAlertsAndSetRead:(BOOL)readBool{
    NSMutableArray * notesArray = [[NSMutableArray alloc]init];
    
    PFQuery * alertQuery = [PFQuery queryWithClassName:@"ShareAlerts"];
    //[alertQuery whereKey:@"read" notEqualTo:@1];
    alertQuery.cachePolicy=kPFCachePolicyNetworkElseCache;
    alertQuery.limit=20;
    [alertQuery selectKeys:@[@"noteObject",@"read"]];
    NSArray * objects = [alertQuery findObjects];
    
    for (PFObject * alert in objects){
        PFObject * object = alert[@"noteObject"];
        NotesObject * noteObject = [[NotesObject alloc] init];
        
        [object fetchIfNeeded];
        
        if ([object isDataAvailable]){
            [alert fetchIfNeeded];
            noteObject.legTags=object[@"legTags"];
            noteObject.noteText=object[@"noteText"];
            noteObject.timestamp=object[@"timeStamp"];
            noteObject.sharingSettings=object.ACL;
            noteObject.objectIDParse=object.objectId;
            noteObject.updatedDate=alert.createdAt;
            noteObject.isEditable=[self findIfEditableForObject:object];
            noteObject.writeAccess=object[@"writeAccess"];
            noteObject.readAccess=object[@"readAccess"];
            noteObject.owner=object[@"owner"];
            noteObject.pfObject=object;
            //public stuff
            //public stuff
            noteObject.upVoted=[(NSArray *)object[@"upVotes"] containsObject:[PFUser currentUser].objectId];
            noteObject.downVoted=[(NSArray *)object[@"downVotes"] containsObject:[PFUser currentUser].objectId];
            noteObject.flagged=[(NSArray *)object[@"flagged"] containsObject:[PFUser currentUser].objectId];
            noteObject.isPublic=[object.ACL getPublicReadAccess];
            noteObject.upCount=((NSArray *)object[@"upVotes"]).count;
            noteObject.downCount=((NSArray *)object[@"downVotes"]).count;
            //setBool based on the NSNumber from Parse
            if (![alert[@"read"] isEqualToNumber:@1])
                noteObject.isNew=YES;
            //This is in case something has been shared withsomeone twice, it doesn't show up twice.
            if (![self findIfArray:notesArray ContainsNoteObject:noteObject])
                [notesArray addObject:noteObject];
            //If we're supposed to mark it as read on the server, do that and save it.
            if (readBool){
                alert[@"read"]=@1;
                [alert saveInBackground];
            }
        }
        //this note was probably deleted, so we're deleting this note alert.
        if (![object isDataAvailable]){
            NSLog(@"Uh oh, we couldn't find the object! We're deleting the alert.");
            [alert deleteInBackground];
        }
    }

    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"updatedDate" ascending:NO];
    [notesArray sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    return notesArray;
}

-(BOOL) findIfEditableForObject:(PFObject *)object{
    if ([object.ACL getWriteAccessForUser:[PFUser currentUser]])
        return YES;
    
    //for each role the user is a member of ask if the role has write access. If it does, return yes
    for (PFRole * userRole in allRoles){
        if ([object.ACL getWriteAccessForRole:userRole]){
            return YES;
            break;
        }
        
    }
    
    return NO;
}
- (BOOL) findIfArray:(NSArray *)array ContainsNoteObject:(NotesObject *)object{
    for (NotesObject * note in array){
        if ([note.objectIDParse isEqualToString:object.objectIDParse]){
            return YES;
            break;
        }
    }
    
    return  NO;
}

//creates an id from a leg object formula is [State][s/h][district] as in MOH051;
- (NSString *) createLegIDforLeg:(Legs *)legislator{
    NSString *state = [[NSUserDefaults standardUserDefaults] objectForKey:@"state"];
    
    int digits = [legislator.district intValue];
    NSString *threeDigits = [NSString stringWithFormat:@"%03d",digits];
    NSString * legID = [NSString stringWithFormat:@"%@%@%@",state,legislator.hstype,threeDigits];
    
    return legID;
}

//only used for saving news stories.
- (void) saveNote{
    
    //note is referenced by self
    if ([self.objectIDParse isEqualToString:@"newnote"]){//new note saving
        PFObject *note = [PFObject objectWithClassName:@"Notes"];
        note[@"noteText"]=self.noteText;
        note[@"timeStamp"]=self.timestamp;
        note[@"savedDate"]=[NSDate date];
        note[@"legTags"]=self.legTags;
        note.ACL=self.sharingSettings;
        note[@"owner"]=[PFUser currentUser];
        note[@"writeAccess"]=self.writeAccess;
        note[@"state"]=[[NSUserDefaults standardUserDefaults]objectForKey:@"state"];
        [note saveInBackground];
        
    }
    else{//existing note saving.
        PFQuery *query = [PFQuery queryWithClassName:@"Notes"];
        
        // Retrieve the object by id
        [query getObjectInBackgroundWithId:self.objectIDParse block:^(PFObject *note, NSError *error) {
            note[@"noteText"]=self.noteText;
            note[@"timeStamp"]=self.timestamp;
            note[@"legTags"]=self.legTags;
            note[@"savedDate"]=[NSDate date];
            note.ACL=self.sharingSettings;
            note[@"owner"]=[PFUser currentUser];
            note[@"writeAccess"]=self.writeAccess;
            [note saveInBackground];
            
        }];

    }
}
//checks if they are owner first, non-owners are simply removed as sharers.
- (void) deleteNote
{
    PFQuery *query = [PFQuery queryWithClassName:@"Notes"];
    
    // Retrieve the object by id
    [query getObjectInBackgroundWithId:self.objectIDParse block:^(PFObject *note, NSError *error) {
        //actually delete it if it's their note.
        PFUser * noteowner = note[@"owner"];
        if ([noteowner.objectId isEqualToString:[PFUser currentUser].objectId]){
            [note deleteInBackground];
        }
        //remove themselves as a sharer if it's not their note.
        else{
            PFACL * newSharing = [PFACL ACL];
            
            for (PFObject *user in self.writeAccess) {
                [user fetchIfNeeded];
                if ([user.objectId isEqualToString:[PFUser currentUser].objectId]){
                    [self.writeAccess removeObject:user];
                }
                else{
                    if ([user isMemberOfClass:[PFRole class]]){
                        [newSharing setReadAccess:YES forRole:(PFRole *)user];
                        [newSharing setWriteAccess:YES forRole:(PFRole *)user];
                    }
                    else{
                        [newSharing setWriteAccess:YES forUser:(PFUser *)user];
                        [newSharing setReadAccess:YES forUser:(PFUser *)user];
                    }
                }
            }
            for (PFObject *user in self.readAccess) {
                [user fetchIfNeeded];
                if ([user.objectId isEqualToString:[PFUser currentUser].objectId]){
                    [self.readAccess removeObject:user];
                }
                else{
                    if ([user isMemberOfClass:[PFRole class]]){
                        [newSharing setReadAccess:YES forRole:(PFRole *)user];
                    }
                    else{
                        [newSharing setReadAccess:YES forUser:(PFUser *)user];
                    }
                }
            }
            [newSharing setPublicWriteAccess:YES];
            
            note[@"writeAccess"]=self.writeAccess;
            if (self.readAccess)
                note[@"readAccess"]=self.readAccess;

            note.ACL = newSharing;
            [note saveInBackground];
        }
        
    }];
}
//saved time for notetable views.
-(NSString *) timeSinceLastSave{
    
    NSTimeInterval secondsSinceSave =[self.updatedDate timeIntervalSinceNow];
    
    if (secondsSinceSave > -60){
        return [NSString stringWithFormat:@"Last saved %0.f seconds ago",-(secondsSinceSave)];
    }
    else if (secondsSinceSave > -60*60){
        return [NSString stringWithFormat:@"Last saved %0.f minutes ago",-(secondsSinceSave/60)];
    }
    else if (secondsSinceSave > -60*60*24){
        return [NSString stringWithFormat:@"Last saved %0.f hours ago",-(secondsSinceSave/60/60)];
    }
    else {
        return [NSString stringWithFormat:@"Last saved %0.f days ago",-(secondsSinceSave/60/60/24)];
    }
    
}

//shared time for alerts.
-(NSString *) timeSinceShared{
    
    NSTimeInterval secondsSinceSave =[self.updatedDate timeIntervalSinceNow];
    
    if (secondsSinceSave > -60){
        return [NSString stringWithFormat:@"First shared %0.f seconds ago",-(secondsSinceSave)];
    }
    else if (secondsSinceSave > -60*60){
        return [NSString stringWithFormat:@"First shared %0.f minutes ago",-(secondsSinceSave/60)];
    }
    else if (secondsSinceSave > -60*60*24){
        return [NSString stringWithFormat:@"First shared %0.f hours ago",-(secondsSinceSave/60/60)];
    }
    else {
        return [NSString stringWithFormat:@"First shared %0.f days ago",-(secondsSinceSave/60/60/24)];
    }
    
}


@end

@implementation UserObject

@synthesize username,realName,realOrg,imageData,email,userObject,isPFRole;

@end
