//
//  TSSharedKeychainPerAppStorage.m
//  Pods
//
//  Created by Mark McFarlane on 08/02/2017.
//
//

#import "TSSharedKeychainPerAppStorage.h"
#import "UICKeyChainStore.h"

NSString * const SHARED_TOKEN_APP_IDS	= @"shared_token_app_ids";		// Used to store all the tokens and other app details for separated token apps
NSString * const TSUserDidLogoutAllAppsNotification	= @"TSUserDidLogoutAllApps";

@implementation TSSharedKeychainPerAppStorage


- (nullable NSString*)token
{
	return self.tokenInfo[OAUTH_TOKEN];
}

- (nullable NSString *)email
{
	return self.tokenInfo[EMAIL];
}

- (nullable NSString *)password
{
	return self.tokenInfo[PASSWORD];
}

- (nullable NSDictionary *)tokenInfo
{
	NSError *error;
	NSData *tokenData = [UICKeyChainStore dataForKey:self.appId service:KEYCHAIN_SERVICE accessGroup:self.accessGroup error:&error];
	NSDictionary *tokenDict = [NSKeyedUnarchiver unarchiveObjectWithData:tokenData];
	NSMutableDictionary *tokenDictForLogging = tokenDict.mutableCopy;
	tokenDictForLogging[@"password"] = @"redacted";
	NSLog(@"Got tokenDict from shared keychain %@ - %s", tokenDictForLogging,__PRETTY_FUNCTION__);
	return tokenDict;
}

- (void)setToken:(NSString *)token email:(NSString *)email password:(NSString *)password
{
	// Store the token and name (for account selection display in UI) for this app separately from the others
	NSMutableDictionary *dictionary = nil;
	if (token) { // If token is nil, we're logging out and want to delete all this, so we leave dictionary as nil.
		dictionary = @{OAUTH_TOKEN : token, APP_NAME : [[NSBundle mainBundle] objectForInfoDictionaryKey:kCFBundleNameKey]}.mutableCopy;
		if (email) {
			dictionary[EMAIL] = email; // If email is present, that means we're logged in.
		}
		if (password) {
			dictionary[PASSWORD] = password;
		}
	}
	NSData *dataForStorage = [NSKeyedArchiver archivedDataWithRootObject:dictionary];
	
	NSError *error;
	BOOL success = [UICKeyChainStore setData:dataForStorage forKey:self.appId service:KEYCHAIN_SERVICE accessGroup:self.accessGroup error:&error];
	if (!success) {
		NSLog(@"Keychain error - %@ - %s",error.localizedDescription,__PRETTY_FUNCTION__);
#warning - We need to do something here, like tell the user!
	} else {
		NSLog(@"%@ - %s",@"stored successfully in keychain",__PRETTY_FUNCTION__);
		
		NSMutableSet<NSString *> *appIDSet = [self appIDsForSharedKeychainSeparatedAppsWithTokens].mutableCopy;
		if (!appIDSet) { // It could be null as tokenDetailsForSharedKeychainSeparatedApps's return value is nullable
			NSLog(@"appIDSet is nil so setting up a new one %@ - %s", appIDSet,__PRETTY_FUNCTION__);
			appIDSet = [NSMutableSet set];
		}
		
		if (token) { // If a token is being set
			[appIDSet addObject:self.appId];
		} else { // If a token is being removed we need to remove this too.
			[appIDSet removeObject:self.appId];
		}
		
		NSData *data = [NSKeyedArchiver archivedDataWithRootObject:appIDSet];
		
		NSError *error;
		BOOL success = [UICKeyChainStore setData:data forKey:SHARED_TOKEN_APP_IDS service:KEYCHAIN_SERVICE accessGroup:self.accessGroup error:&error];
		if (!success) {
			NSLog(@"Keychain error - %@ - %s",error.localizedDescription,__PRETTY_FUNCTION__);
#warning - We need to do something here, like tell the user!
		} else {
			// We're good to go!
			NSLog(@"Successfully stored %@ in SHARED_TOKEN_APP_IDS - %s", appIDSet,__PRETTY_FUNCTION__);
			NSLog(@"%@ - %s",[self appIDsForSharedKeychainSeparatedAppsWithTokens],__PRETTY_FUNCTION__);
		}
	}
	
	// If we're only allowing one account for the shared login, we need to ensure all tokens for other apps are also destroyed.
	if (!token) {
		// We need to clear out each token for all apps in the accessGroup! ... if they're not email logged in!
		// Then clear the list of appIDs with tokens.
		
		NSSet<NSString *> *existingAppIDSet = [self appIDsForSharedKeychainSeparatedAppsWithTokens];
		NSMutableSet<NSString *> *appIDSet = existingAppIDSet.mutableCopy; // So we can remove items
		for (NSString *appID in existingAppIDSet) {
			NSData *data = [UICKeyChainStore dataForKey:appID service:KEYCHAIN_SERVICE accessGroup:self.accessGroup error:&error];
			NSDictionary *dict = [NSKeyedUnarchiver unarchiveObjectWithData:data];
			if (dict[EMAIL]) {
				// It's logged in, so we need to remove it.
				[UICKeyChainStore removeItemForKey:appID service:KEYCHAIN_SERVICE accessGroup:self.accessGroup error:&error];
				[appIDSet removeObject:appID];
			}
		}
		
		// At this point appIDSet should only contain entries for anonymous tokens/sessions
		NSData *data = [NSKeyedArchiver archivedDataWithRootObject:appIDSet];
		
		NSError *error;
		BOOL success = [UICKeyChainStore setData:data forKey:SHARED_TOKEN_APP_IDS service:KEYCHAIN_SERVICE accessGroup:self.accessGroup error:&error];
		if (!success) {
			NSLog(@"Keychain error - %@ - %s",error.localizedDescription,__PRETTY_FUNCTION__);
#warning - We need to do something here, like tell the user!
		}
		
		[[NSNotificationCenter defaultCenter] postNotificationName:TSUserDidLogoutAllAppsNotification object:nil];
	}
}


- (nullable NSSet<NSDictionary *> *)tokenDetailsForSharedKeychainSeparatedAppsThatCanBeExchangedForTokenForCurrentApp
{
	NSMutableSet *idSet = [self appIDsForSharedKeychainSeparatedAppsWithTokens].mutableCopy;
	//		NSLog(@"idSet before removal: %@ - %s", idSet,__PRETTY_FUNCTION__);
	
	[idSet removeObject:self.appId];
	
	//		NSLog(@"idSet after removal: %@ - %s", idSet,__PRETTY_FUNCTION__);
	
	NSMutableSet<NSDictionary *> *tokenSet = [NSMutableSet set];
	
	for (NSString *appID in idSet) {
		NSError *error;
		NSData *tokenData = [UICKeyChainStore dataForKey:appID service:KEYCHAIN_SERVICE accessGroup:self.accessGroup error:&error];
		NSDictionary *tokenDict = [NSKeyedUnarchiver unarchiveObjectWithData:tokenData];
		if (tokenDict[EMAIL]) {
			// Only if the email exists, as this means the user is logged in, not just an anonymous session token.
			[tokenSet addObject:tokenDict];
			//			NSLog(@"Added token because it's logged in: %@ - %s",tokenDict,__PRETTY_FUNCTION__);
		} else {
			//			NSLog(@"Didn't add token because it's not logged in: %@ - %s",tokenDict,__PRETTY_FUNCTION__);
		}
	}
	
	return tokenSet;
}

- (nullable NSSet<NSString *> *)appIDsForSharedKeychainSeparatedAppsWithTokens
{
	if (!self.accessGroup) {
		[NSException raise:NSInternalInconsistencyException format:@"tokenDetailsForSharedKeychainSeparatedApps was called but sharedKeychainAccessGroup has not been set yet."];
	}
	
	// Now ensure that the app ID is entered into the list of app IDs with a token
	NSError *error;
	NSData *appIDSetData = [UICKeyChainStore dataForKey:SHARED_TOKEN_APP_IDS service:KEYCHAIN_SERVICE accessGroup:self.accessGroup error:&error];
	if (!appIDSetData && error) {
		NSLog(@"tokenDetailsForSharedKeychainSeparatedApps error: %@ - %s",error,__PRETTY_FUNCTION__);
		// Something went wrong
#warning Handle this?
		return nil;
	} else {
		// This could be nil
		NSSet *set = [NSKeyedUnarchiver unarchiveObjectWithData:appIDSetData];
		return set;
	}
}

- (nonnull NSString *)appId
{
	return [[NSBundle mainBundle] bundleIdentifier];
}

- (void)clearKeychain
{
	NSError *error;
	BOOL success = [UICKeyChainStore removeAllItemsForService:KEYCHAIN_SERVICE accessGroup:self.accessGroup error:&error];
	if (!success) {
		NSLog(@"Clear keychain failed: %@ - %s",error,__PRETTY_FUNCTION__);
	} else {
		NSLog(@"Keychain cleared! %@ - %s",self,__PRETTY_FUNCTION__);
	}
}

@end
