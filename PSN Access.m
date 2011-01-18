#import <Foundation/Foundation.h>
#import "PSNAccess.h"

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	NSString * username = @"your_PSN_login_id";
	
	char password[512];
	printf("Password: ");
	fgets(password, 512, stdin);
	password[strlen(password) - 1] = 0;
	NSString * pwd = [NSString stringWithUTF8String:password];
	
	PSNLogin(username, pwd);
	NSArray * friends = friendsList(fetchFriendList());
	NSLog(@"%@", friends);
	for (NSString * friend in friends) {
		NSLog(@"%@: %@", friend, friendGame(friendInfo(friend)));
	}
	
    [pool drain];
    return 0;
}
