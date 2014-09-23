//
//  VoteTrackers.m
//  CapitolBuddy
//
//  Created by Paul Rolfe on 9/24/13.
//  Copyright (c) 2013 Paul Rolfe. All rights reserved.
//

#import "VoteTrackers.h"

@implementation VoteTrackers
@synthesize billName,billHStype,badVotes,goodVotes,swingVotes,targetState,uniqueRowID;

-(id) initWithUniqueId:(int)rowID billName:(NSString *)_billName billHStype:(NSString *)_billHStype goodVotes:(NSArray *)_goodVotes badVotes:(NSArray *)_badVotes swingVotes:(NSArray *)_swingVotes targetState:(NSString *)_targetState{
    if ((self = [super init])) {
        self.uniqueRowID=rowID;
        self.billName=_billName;
        self.billHStype=_billHStype;
        self.goodVotes=_goodVotes;
        self.badVotes=_badVotes;
        self.swingVotes=_swingVotes;
        self.targetState=_targetState;
    }
    return self;
}
@end
