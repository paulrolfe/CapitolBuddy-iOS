//
//  ShareActions.m
//  CapitolBuddy
//
//  Created by Paul Rolfe on 4/25/14.
//  Copyright (c) 2014 Paul Rolfe. All rights reserved.
//

#import "ShareActions.h"

@implementation ShareActions

@synthesize rootViewController,messageBody,messageTitle;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}
- (instancetype)initWithItem:(NotesObject *)item {
    
    self = [super initWithTitle:@"Share your note"
                       delegate:nil
              cancelButtonTitle:nil
         destructiveButtonTitle:nil
              otherButtonTitles:nil, nil];
    
    if (self) {
        _item = item;
    }
    return self;
}
+ (instancetype)actionSheetForItem:(NotesObject *)item
{
	ShareActions *as = [[self alloc] initWithItem:item];
	as.delegate = as;
    [as populateButtons];
    return as;
}
- (void)populateButtons {
    
    [self addButtonWithTitle:@"Email"]; //index 0
    [self addButtonWithTitle:@"Message"]; //index 1
    [self addButtonWithTitle:@"Copy Text"]; //index 2
    /*[self addButtonWithTitle:@"Facebook"]; //index 3
    [self addButtonWithTitle:@"Twitter"]; //index 4*/
	
	// Add Cancel button
	[self addButtonWithTitle:@"Cancel"];
	self.cancelButtonIndex = self.numberOfButtons -1;
}
-(void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex==0){
        //bring up mail compose
        [self email];
    }
    else if (buttonIndex==1){
        //bring up messages
        [self message];
    }
    else if (buttonIndex==2){
        //copy text to clipboard
        [self copyText];
    }
    /*else if (buttonIndex==3){
        //bring up FB share
        [self facebook];
    }
    else if (buttonIndex==4){
        //bring up tweet
        [self twitter];
    }*/

}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)email {

     if ([MFMailComposeViewController canSendMail])
     {
         MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
         mailer.mailComposeDelegate = (NotesViewController *)rootViewController;
         
         [mailer setSubject:messageTitle];
         NSArray *toRecipients = [NSArray arrayWithObjects:[PFUser currentUser].email,nil];
         [mailer setToRecipients:toRecipients];
         
         [mailer setMessageBody:messageBody isHTML:NO];
         [rootViewController presentViewController:mailer animated:YES completion:nil];
     }
     else
     {
         UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failure" message:@"Your device doesn't support the composer sheet" delegate:nil cancelButtonTitle:@"OK"otherButtonTitles:nil];
         [alert show];
     }
}
-(void) message{
    if ([MFMessageComposeViewController canSendText])
    {
        MFMessageComposeViewController *messenger = [[MFMessageComposeViewController alloc] init];
        messenger.messageComposeDelegate = (NotesViewController *)rootViewController;
        
        messenger.body = messageBody;
        
        [rootViewController presentViewController:messenger animated:YES completion:nil];
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failure" message:@"Your device doesn't support the messaging feature" delegate:nil cancelButtonTitle:@"OK"otherButtonTitles:nil];
        [alert show];
    }
}
-(void)copyText{
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = messageBody;
}
-(void)twitter{
    NSString * tweetString = [NSString stringWithFormat:@"via #CapBud: %@",messageBody];
    //trim to 140 char
    tweetString = [tweetString substringToIndex:139];
    //make url encoded correctly
    tweetString = [tweetString stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
    //add url part
    tweetString = [NSMutableString stringWithFormat:@"twitter://post?message=%@",tweetString];
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:tweetString]];
}
-(void)facebook{
    NSMutableString * tweetString = [NSMutableString stringWithFormat:@"%@:\n%@",messageTitle,messageBody];
    //make url encoded correctly
    [tweetString stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"fb://profile"]];
}


@end
