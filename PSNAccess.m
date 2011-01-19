/*
 *  PSNAccess.c
 *  PSN Access
 *
 *  Created by Alex Nichol on 1/18/11.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#import "PSNAccess.h"

BOOL PSNLogin (NSString * username, NSString * password) {
	NSURL * url = [NSURL URLWithString:@"https://store.playstation.com/external/login.action"];
	NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:url];
	[request setTimeoutInterval:10];
	NSString * returnURL = @"http://us.playstation.com/uwps/HandleIFrameRequests";
	NSString * post = [NSString stringWithFormat:@"&loginName=%@&password=%@&returnURL=%@",
					   username, password, returnURL];
	NSString * length = [NSString stringWithFormat:@"%d", [post length]];
	NSData * postData = [post dataUsingEncoding:NSUTF8StringEncoding];
	
	// configure the request
	[request setHTTPBody:postData];
	[request setValue:length forHTTPHeaderField:@"Content-Length"];
	[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	[request setHTTPMethod:@"POST"];
	
	NSArray * allCookies = nil;
	NSData * returnData = [AllCookieFetcher allCookiesFromRequest:request cookies:&allCookies];
	
	[request release];
	
	[[NSHTTPCookieStorage sharedHTTPCookieStorage]
	 setCookies:allCookies
	 forURL:[NSURL URLWithString:@"http://us.playstation.com/"]
	 mainDocumentURL:nil];
	
	NSString * data = [[[NSString alloc] initWithData:returnData
											 encoding:NSWindowsCP1252StringEncoding] autorelease];
	
	if ([data rangeOfString:@"is not correct."].location == NSNotFound) {
		return YES;
	} else return NO;
	
	
}

NSString * fetchFriendList () {
	// fetch the HTML of their friends list
	// further parsing needs to be applied
	NSString * urlString = [NSString stringWithFormat:@"http://us.playstation.com/playstation/psn/profile/friends?id=0.%d", arc4random()];
	NSURL * url = [NSURL URLWithString:urlString];
	NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:url];
	
	[request setValue:@"http://us.playstation.com/myfriends" forHTTPHeaderField:@"Referer"];
	
	NSURLResponse * response = nil;
	
	NSData * d = [NSURLConnection sendSynchronousRequest:request
									   returningResponse:&response
												   error:nil];
	
	return [[[NSString alloc] initWithData:d encoding:NSWindowsCP1252StringEncoding] autorelease];
}

NSArray * friendsList (NSString * friendsHTML) {
	// parse the friends HTML
	NSString * username = nil;
	NSMutableArray * addArray = [NSMutableArray array];
	NSString * newHTML = friendsHTML;
	do {
		NSRange r = [newHTML rangeOfString:@"<div class=\"slot\">"];
		if (r.location == NSNotFound) break;
		// read their name
		newHTML = [newHTML substringFromIndex:r.location + r.length];
		r = [newHTML rangeOfString:@"<div id=\""];
		newHTML = [newHTML substringFromIndex:r.location+r.length];
		r = [newHTML rangeOfString:@"\""];
		username = [newHTML substringToIndex:r.location];
		newHTML = [newHTML substringFromIndex:r.location + r.length];
		[addArray addObject:username];
	} while (username);
	return addArray;
}

NSString * friendInfo (NSString * username) {
	// get the friend info HTML page
	// for a perticular friend.
	NSString * urlString = [NSString stringWithFormat:@"http://us.playstation.com/playstation/psn/profile/%@?id=0.%d", username, arc4random()];
	NSURL * url = [NSURL URLWithString:urlString];
	NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:url];
	[request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
	[request setValue:[NSString stringWithFormat:@"http://us.playstation.com/playstation/psn/profile/friends?id=0.%d", arc4random()] forHTTPHeaderField:@"Referer"];
	
	NSURLResponse * response = nil;
	
	NSData * d = [NSURLConnection sendSynchronousRequest:request
									   returningResponse:&response
												   error:nil];
	
	return [[[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding] autorelease];
	
}

NSString * friendGame (NSString * friendData) {
	// get the current game (status) from a friendData
	// returned by friendInfo().
	NSRange index = [friendData rangeOfString:@"<span class=\"_iamplaying_\""];
	if (index.location == NSNotFound) return nil;
	NSString * string = [friendData substringFromIndex:index.location];
	NSRange closeSpan = [string rangeOfString:@">"];
	if (closeSpan.location == NSNotFound) return nil;
	string = [string substringFromIndex:closeSpan.location + closeSpan.length];
	NSRange closeSpanIndex = [string rangeOfString:@"</span>"];
	if (closeSpanIndex.location == NSNotFound) return nil;
	string = [string substringToIndex:closeSpanIndex.location];
	
	NSMutableString * game = [NSMutableString stringWithString:string];
	for (int i = 0; i < [game length]; i++) {
		if (!isalnum([game characterAtIndex:i])) {
			[game deleteCharactersInRange:NSMakeRange(i, 1)];
			i -= 1;
		} else break;
	}
	
	return game;
}

void PSNLogout() {
	// delete all PSN cookies
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	NSMutableArray * a = [NSMutableArray array];
	for (NSHTTPCookie * c in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]) {
		if ([[c domain] rangeOfString:@".playstation.com"].location != NSNotFound) [a addObject:c];
	}
	for (id c in a) {
		[[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:c];
	}
	[pool drain];
}

#pragma mark AllCookieFetcher

@implementation AllCookieFetcher

@synthesize allCookies;
@synthesize readData;
@synthesize done;

- (NSURLRequest *)connection:(NSURLConnection *)connection
             willSendRequest:(NSURLRequest *)inRequest
            redirectResponse:(NSURLResponse *)response {
	// append to the array
	if (!response) return inRequest;
	if (!self.allCookies) self.allCookies = [NSArray array];
	NSArray * _allCookies = [NSHTTPCookie cookiesWithResponseHeaderFields:[(NSHTTPURLResponse *)response allHeaderFields]
																   forURL:nil];
	self.allCookies = [self.allCookies arrayByAddingObjectsFromArray:_allCookies];
	return inRequest;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	if (!self.readData) {
		self.readData = [NSMutableData data];
	}
	[self.readData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	if (!self.allCookies) {
		self.allCookies = [NSArray array];
		NSArray * _allCookies = [NSHTTPCookie cookiesWithResponseHeaderFields:[(NSHTTPURLResponse *)response allHeaderFields]
																	   forURL:nil];
		self.allCookies = [self.allCookies arrayByAddingObjectsFromArray:_allCookies];
	}
	self.readData = nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	done = YES;
}

+ (NSData *)allCookiesFromRequest:(NSURLRequest *)request cookies:(NSArray **)cookies {
	// fetch it
	AllCookieFetcher * delegate = [[AllCookieFetcher alloc] init];
	NSURLConnection * urlConnection = [[NSURLConnection alloc] initWithRequest:request
																	  delegate:delegate];
	[urlConnection start];
	while (![delegate done]) {
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
	}
	NSArray * array = [[delegate allCookies] retain];
	NSData * d = [[delegate readData] retain];
	[delegate release];
	*cookies = [array autorelease];
	return [d autorelease];
}

- (void)dealloc {
	self.allCookies = nil;
	self.readData = nil;
	[super dealloc];
}

@end
