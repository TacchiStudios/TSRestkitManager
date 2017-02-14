//
//  TSSharedKeychainStorage.m
//  Pods
//
//  Created by Mark McFarlane on 08/02/2017.
//
//

#import "TSSharedKeychainStorage.h"
#import "UICKeyChainStore.h"

@implementation TSSharedKeychainStorage

- (void)setToken:(NSString *)token email:(NSString *)email password:(NSString *)password
{
	// Store the token and name (for account selection display in UI) for this app separately from the others
	NSDictionary *dictionary = nil;
	if (token) { // If token is nil, we're logging out and want to delete all this, so we leave dictionary as nil.
		if (email) {
			dictionary = @{OAUTH_TOKEN : token, EMAIL : email, PASSWORD : password}; // If email is present, that means we're logged in.
		} else {
			dictionary = @{OAUTH_TOKEN : token}; // If email is nil, we don't put it in the dict, which means we're not logged in and have an anonymous session token.
		}
	}
	NSData *dataForStorage = [NSKeyedArchiver archivedDataWithRootObject:dictionary];
	
	NSError *error;
	BOOL success = [UICKeyChainStore setData:dataForStorage forKey:KEYCHAIN_TOKEN_KEY service:KEYCHAIN_SERVICE accessGroup:self.accessGroup error:&error];
	if (!success) {
		NSLog(@"Keychain error - %@ - %s",error.localizedDescription,__PRETTY_FUNCTION__);
#warning - We need to do something here, like tell the user!
	}
	
	//	NSError *error;
	//	BOOL success = [UICKeyChainStore setString:token forKey:KEYCHAIN_TOKEN_KEY service:KEYCHAIN_SERVICE accessGroup:self.accessGroup error:&error]; // sharedKeychainAccessGroup may be nil, in which case this just stores in local keychain only.
	//	if (!success) {
	//		NSLog(@"Keychain error - %@ - %s",error.localizedDescription,__PRETTY_FUNCTION__);
	//#warning - We need to do something here, like tell the user!
	//	} else {
	//		NSLog(@"%@ - %s",@"stored successfully in keychain",__PRETTY_FUNCTION__);
	//	}
}

@end
