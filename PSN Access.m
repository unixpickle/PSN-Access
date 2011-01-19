#import <Foundation/Foundation.h>
#import "PSNAccess.h"

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	NSString * username = @"your_psn_here";
	
	printf("Logging in as %s", [username UTF8String]);
	
	char password[512];
	printf("Password: ");
	fgets(password, 512, stdin);
	password[strlen(password) - 1] = 0;
	NSString * pwd = [NSString stringWithUTF8String:password];
	
	if (!PSNLogin(username, pwd)) {
		NSLog(@"Login incorrect.");
		return -1;
	}
	
	NSArray * friends = friendsList(fetchFriendList());
	NSLog(@"%@", friends);
	for (NSString * friend in friends) {
		NSLog(@"%@: %@", friend, friendGame(friendInfo(friend)));
	}
	
	PSNLogout();
	
    [pool drain];
    return 0;
}
