/*
 *  PSNAccess.h
 *  PSN Access
 *
 *  Created by Alex Nichol on 1/18/11.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#import <Foundation/Foundation.h>

// method to authenticate with the PlayStation Network.
// this needs to be called before any other functions
// that can access your person PSN data.
BOOL PSNLogin (NSString * username, NSString * password);
// get the HTML page for the current users friend list.
// this will need further parsing before use.
NSString * fetchFriendList ();
// get a list of friends user names
// from a friends list
NSArray * friendsList (NSString * friendsHTML);
// get the HTML page for a particular friend.
// this needs further parsing.
NSString * friendInfo (NSString * username);
// get the current game of a friend's HTML info.
// this would be something like:
// Call of Duty®: Black ops
NSString * friendGame (NSString * friendData);

#pragma mark AllCookieFetcher

@interface AllCookieFetcher : NSObject {
	NSArray * allCookies;
	NSMutableData * readData;
	BOOL done;
}

@property (nonatomic, retain) NSArray * allCookies;
@property (nonatomic, retain) NSMutableData * readData;
@property (readwrite) BOOL done;

- (NSURLRequest *)connection:(NSURLConnection *)inConnection
             willSendRequest:(NSURLRequest *)inRequest
            redirectResponse:(NSURLResponse *)inRedirectResponse;

+ (NSData *)allCookiesFromRequest:(NSURLRequest *)request cookies:(NSArray **)cookies;

@end
