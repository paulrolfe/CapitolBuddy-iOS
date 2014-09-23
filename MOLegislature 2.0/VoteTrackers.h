//
//  VoteTrackers.h
//  CapitolBuddy
//
//  Created by Paul Rolfe on 9/24/13.
//  Copyright (c) 2013 Paul Rolfe. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VoteTrackers : NSObject

@property NSString * billName;
@property NSString * billHStype;
@property NSArray * goodVotes;
@property NSArray * badVotes;
@property NSArray * swingVotes;
@property NSString * targetState;
@property int uniqueRowID;

-(id) initWithUniqueId:(int)rowID billName:(NSString *)_billName billHStype:(NSString *)_billHStype goodVotes:(NSArray *)_goodVotes badVotes:(NSArray *)_badVotes swingVotes:(NSArray *)_swingVotes targetState:(NSString *)_targetState;


@end
