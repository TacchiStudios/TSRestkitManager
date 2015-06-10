//
//  TSUser.m
//
//  Created by Mark McFarlane on 27/05/2015.
//  Copyright (c) 2015 Tacchi Studios. All rights reserved.
//

#import "TSUser.h"
#import <Restkit.h>
#import <TSRestkitManager.h>

NSString * const TSUserDidStartLoginNotification				= @"TSUserDidStartLoginNotification";
NSString * const TSUserDidLoginNotification						= @"TSUserDidLoginNotification";
NSString * const TSUserDidFailLoginNotification					= @"TSUserDidFailLoginNotification";

NSString * const TSUserDidLogoutNotification					= @"TSUserDidLogoutNotification";

NSString * const TSUserDidStartGettingSessionTokenNotification	= @"TSUserDidStartGettingSessionTokenNotification";
NSString * const TSUserDidGetSessionTokenNotification			= @"TSUserDidGetSessionTokenNotification";
NSString * const TSUserDidFailGettingSessionTokenNotification	= @"TSUserDidFailGettingSessionTokenNotification";

NSString * const TSUserDidStartCreatingAccountNotification		= @"TSUserDidStartCreatingAccountNotification";
NSString * const TSUserDidCreateAccountNotification				= @"TSUserDidCreateAccountNotification";
NSString * const TSUserDidFailCreatingAccountNotification		= @"TSUserDidFailCreatingAccountNotification";

NSString * const TSUserDidStartUpdatingUserDetailsNotification	= @"TSUserDidStartUpdatingUserDetailsNotification";
NSString * const TSUserDidUpdateUserDetailsNotification			= @"TSUserDidUpdateUserDetailsNotification";
NSString * const TSUserDidFailUpdatingUserDetailsNotification	= @"TSUserDidFailUpdatingUserDetailsNotification";

NSString * const TSUserDidStartForgotPasswordNotification		= @"TSUserDidStartForgotPasswordNotification";
NSString * const TSUserDidFinishForgotPasswordNotification		= @"TSUserDidFinishForgotPasswordNotification";
NSString * const TSUserDidFailForgotPasswordNotification		= @"TSUserDidFailForgotPasswordNotification";


NSString * const OAUTH_TOKEN	= @"oauth_token";
NSString * const EMAIL			= @"email_address";
NSString * const PASSWORD		= @"password";


#warning Remove!
#import "AFOAuth2Client.h"

@interface TSUser()

#warning Remove!
@property (nonatomic, strong) AFOAuth2Client *oauthClient;

@property (nonatomic) BOOL allowsAnonymousSessions;
@property (nonatomic, copy) NSString *anonymousSessionPath, *anonymousSessionUsername, *anonymousSessionPassword;
@property (nonatomic, copy) NSString *clientId, *clientSecret;

@end

@implementation TSUser

#pragma mark -
#pragma mark Singleton

+ (instancetype)sharedTSUser
{
	static dispatch_once_t once;
	static id sharedInstance;
	dispatch_once(&once, ^{
		sharedInstance = [[self alloc] init];
	});
	return sharedInstance;
}

- (instancetype)init
{
	self = [super init];
	
	if (self) {
	}
	
	return self;
}

#pragma mark -

- (void)setupAuthHeader
{
	if ([self oauthCredential]) { // anon style
		NSLog(@"Setting up oAuth token: %@ - %s",[self oauthCredential].accessToken,__PRETTY_FUNCTION__);
		[[RKObjectManager sharedManager].HTTPClient setDefaultHeader:@"Authorization" value:[NSString stringWithFormat:@"Bearer %@", [self oauthCredential].accessToken]];
	} else if ([self isLoggedIn]) { // normal style
		[[RKObjectManager sharedManager].HTTPClient setDefaultHeader:@"Authorization" value:[NSString stringWithFormat:@"Bearer %@", [self oAuthToken]]];
	} else {
		NSLog(@"%@ - %s",@"Not logged in so not setting up oAuth token",__PRETTY_FUNCTION__);
	}
}

- (AFOAuthCredential *)oauthCredential
{
	return nil;
//	return [AFOAuthCredential retrieveCredentialWithIdentifier:self.oauthClient.serviceProviderIdentifier];
}

- (void)setClientId:(NSString *)clientId secret:(NSString *)clientSecret
{
	self.clientId = clientId;
	self.clientSecret = clientSecret;
}

- (void)enableAnonymousSessionsWithPath:(NSString *)path username:(NSString *)username password:(NSString *)password clientID:(NSString *)clientID secret:(NSString *)secret
{
	self.allowsAnonymousSessions = YES;
	
	self.anonymousSessionPath = path;
	self.anonymousSessionUsername = username;
	self.anonymousSessionPassword = password;
	
	//		self.oauthClient = [SLEOauthClient clientWithBaseURL:[[RKObjectManager sharedManager] baseURL] clientID:OAUTH_CLIENT_ID secret:OAUTH_CLIENT_SECRET];
}

- (void)createSession
{
	NSAssert(self.allowsAnonymousSessions, nil);
	
	// If session exists, ignore this
	if ([self hasSessionToken]) {
		return;
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:TSUserDidStartGettingSessionTokenNotification object:nil];
	
	
	[self.oauthClient authenticateUsingOAuthWithPath:self.anonymousSessionPath
											username:self.anonymousSessionUsername
											password:self.anonymousSessionPassword
											   scope:nil
											 success:^(AFOAuthCredential *credential) {
												 NSLog(@"I have a token! %@", credential.accessToken);
												 [AFOAuthCredential storeCredential:credential withIdentifier:self.oauthClient.serviceProviderIdentifier];
												 
												 [self setupAuthHeader];
												 
												 [[NSNotificationCenter defaultCenter] postNotificationName:TSUserDidGetSessionTokenNotification object:nil];
											 }
											 failure:^(NSError *error) {
												 NSLog(@"Error: %@", error);
												 
#warning handle!
//												 [UIAlertView alertViewWithTitle:@"Couldn't initiate" message:@"Please try again now or close the app and try later" cancelButtonTitle:nil otherButtonTitles:@[@"Retry"] onDismiss:^(int buttonIndex, UIAlertView *alertView) {
//													 [self createSession];
//												 } onCancel:nil];
											 }];
}

- (void)loginWithEmail:(NSString *)email password:(NSString *)password
{
	if (self.allowsAnonymousSessions) {
		NSAssert([self hasSessionToken], @"MUST HAVE A SESSION OAUTH TOKEN");
		
		[[[RKObjectManager sharedManager] HTTPClient] postPath:self.sessionUserConnectionPath parameters:@{@"username": email, @"password": password} success:^(AFHTTPRequestOperation *operation, id responseObject) {
			[self handleLoginWithAnonymousSessionWithResponseObject:responseObject];
		} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
			NSLog(@"%@ - %s",error.localizedDescription,__PRETTY_FUNCTION__);
			
#warning put back in
//			NSString *message = operation.response.statusCode == 401 ? SLELocalizedStringIncorrectEmailOrPassword : SLELocalizedStringErrorTryAgain;
//			[self loginFailed:message];
			
			[[NSNotificationCenter defaultCenter] postNotificationName:TSUserDidFailLoginNotification object:nil userInfo:nil];
		}];
	} else {
		email = [email stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"]; // + doesn't get URL escaped so we do this. Another option could be to use CFURLCreateStringByAddingPercentEscapes, but that may be overkill
		
		NSString *httpBody = [NSString stringWithFormat:@"client_id=%@&client_secret=%@&username=%@&password=%@&grant_type=password", self.clientId, self.clientSecret,	email, password];
		
		NSString *urlString = [NSString stringWithFormat:@"%@/%@", self.baseURL, self.loginPath];
		

		NSMutableURLRequest *request = [[RKObjectManager sharedManager].HTTPClient requestWithMethod:@"POST" path:urlString parameters:nil];
		[request setHTTPBody:[httpBody dataUsingEncoding:NSUTF8StringEncoding]];
		
		AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
		[operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
			
			NSLog(@"Did load response - %@ - %s",operation.responseString,__PRETTY_FUNCTION__);
			
			if (operation.hasAcceptableStatusCode) {
				NSDictionary *parsedResponse = [NSJSONSerialization JSONObjectWithData:operation.responseData options:0 error:nil]; // operation.responseData == responseObject
				
				NSString *accessToken = [parsedResponse objectForKey:@"access_token"];
				
				[self handleSuccessfulLoginWithEmail:email password:password token:accessToken];
			} else {
				[self handleLoginError:nil response:operation];
			}
		} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
			[self handleLoginError:error response:operation];
		}];
		[operation start];
	}
}

- (void)handleSuccessfulLoginWithEmail:(NSString *)email password:(NSString *)password token:(NSString *)accessToken
{
	if (self.spoofAccessToken) {
		accessToken = self.spoofAccessToken;
	}
	
	[self setUserDefaultsWithEmail:email password:password token:accessToken];
	
	[self setupAuthHeader];
	
#warning Take these out, they should be done on either a notification or in a block
//	[Flurry setUserID:email];
//	[Flurry logEvent:SLEFlurryEventUserLoggedIn];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:TSUserDidLoginNotification object:self];
}

- (void)setUserDefaultsWithEmail:(NSString *)email password:(NSString *)password token:(NSString *)accessToken
{
#warning PASSWORD???
	[[NSUserDefaults standardUserDefaults] setObject:accessToken forKey:OAUTH_TOKEN];
	[[NSUserDefaults standardUserDefaults] setObject:email forKey:EMAIL];
	[[NSUserDefaults standardUserDefaults] setObject:password forKey:PASSWORD]; // For the relogin thing :(
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)isLoggedIn
{
	#warning Should this be EMAIL if we're allowing anon sessions?
	return [[self oAuthToken] length] > 0;
}

- (NSString *)oAuthToken
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:OAUTH_TOKEN];
}


- (void)handleLoginWithAnonymousSessionWithResponseObject:(id)responseObject
{
	// Check meta key path and act accordingly
	// supply_pwd_to_create_account | email_missing | account_linked | user_mismatch | account_creation_failed | account_exists_wrong_password
	
	NSAssert([responseObject isKindOfClass:[NSDictionary class]], @"THIS SHOULD BE A DICTIONARY!");
	
	NSString *linkStatus = [[responseObject objectForKey:@"meta"] objectForKey:@"status"];
	NSDictionary *userDict = [responseObject objectForKey:@"user"];
	
	if ([linkStatus isEqualToString:@"account_linked"]) { // This is either a normal SL account or facebook account
		NSLog(@"account_linked - Got USER! %@ - %s",userDict,__PRETTY_FUNCTION__);

		#warning put back in
//		[self setUserDetails:userDict];
		
//		[[NSNotificationCenter defaultCenter] postNotificationName:SLEUserDidLoginNotification object:nil];
		
	} else if ([linkStatus isEqualToString:@"email_missing"]) {
		NSLog(@"email_missing - Got USER %@ - %s",userDict,__PRETTY_FUNCTION__);
		
#warning put back in
//		[UIAlertView alertViewWithTitle:SLELocalizedStringNoEmailAddress message:SLELocalizedStringYourAccountDoesntHaveEmail];
//		[self handleCreateFailed];
	} else if ([linkStatus isEqualToString:@"supply_pwd_to_create_account"]) {
		NSLog(@"supply_pwd_to_create_account - Got USER %@ - %s",userDict,__PRETTY_FUNCTION__);
		
		// Get password from user (inform account creation)
		
		#warning put back in
//		[UIAlertView alertViewWithTitle:[NSString stringWithFormat:SLELocalizedStringCreateAccountFor, [userDict objectForKey:@"email"]] style:UIAlertViewStyleSecureTextInput message:[NSString stringWithFormat:SLELocalizedStringPleaseEnterAPassword] cancelButtonTitle:SLELocalizedStringCancel otherButtonTitles:@[@"Create"] onDismiss:^(int buttonIndex, UIAlertView *alertView) {
			// Send to server then dismiss
//			[[SLEUser sharedSLEUser] connectFacebook:[FBSession activeSession].accessTokenData.accessToken password:[alertView textFieldAtIndex:0].text];
//		} onCancel:^{
//			[UIAlertView alertViewWithTitle:SLELocalizedStringAccountNotCreated message:nil];
//			[self handleCreateFailed];
//		}];
//	} else if ([linkStatus isEqualToString:@"user_mismatch"]) {
//		[UIAlertView alertViewWithTitle:SLELocalizedStringFacebookAlreadyLinkedToOther message:SLELocalizedStringPleaseCallCustomerServices];
//		[self handleCreateFailed];
//	} else if ([linkStatus isEqualToString:@"account_creation_failed"]) {
//		[UIAlertView alertViewWithTitle:SLELocalizedStringAccountCreationFailed message:[[[responseObject objectForKey:@"ec_cube"] objectForKey:@"error_details"] lastObject]];
//		[self handleCreateFailed];
//	} else if ([linkStatus isEqualToString:@"account_exists_wrong_password"]) {
//		[UIAlertView alertViewWithTitle:SLELocalizedStringAccountExists message:SLELocalizedStringPleaseLoginAndConnect];
//		[self handleCreateFailed];
//	} else {
//		NSLog(@"%@ - %s",@"hmm, no known link status",__PRETTY_FUNCTION__);
	}
}

- (void)handleLoginError:(NSError *)error response:(AFHTTPRequestOperation *)operation
{
	NSString *message = operation.responseString;
	
	NSLog(@"%@ - %s",message, __PRETTY_FUNCTION__);
	
	if (operation.responseData) {
		NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:operation.responseData options:0 error:nil];
		
		if ([responseDict objectForKey:@"error_description"]) {
			message = [responseDict objectForKey:@"error_description"];
		} else if ([responseDict objectForKey:@"error"]) {
			message = [responseDict objectForKey:@"error"];
		} else if (operation) {
			switch (operation.response.statusCode) {
					// TODO: add more?
				case 500:
					message = NSLocalizedString(@"Sorry, we had a problem with the server. If the error persists, please contact us.", @"Login 500 error alert");
					break;
				case 503:
					message = NSLocalizedString(@"Sorry the server is undergoing maintenance. Please try again later.", @"Login 503 error alert");
					break;
				default:
					break;
			}
		}
	} else if (error) {
		if (![TSRestkitManager isNetworkReachable]) {
			message = @"No internet available. Please check your connection and try again";
		#warning put back in
//			message = SLELocalizedStringDeviceOffline;
		}
	}
	
	#warning put back in
//	[self loginFailed:message];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:TSUserDidFailLoginNotification object:message];

}

- (void)handleCreateFailed
{
	[[NSNotificationCenter defaultCenter] postNotificationName:TSUserDidFailCreatingAccountNotification object:nil];
}

- (void)forgotPasswordForUserParams:(NSDictionary *)params
{
	[[NSNotificationCenter defaultCenter] postNotificationName:TSUserDidStartForgotPasswordNotification object:nil];
	
	[[RKObjectManager sharedManager].HTTPClient postPath:self.forgotPasswordPath parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
		NSLog(@"%@ - %s",operation.responseString,__PRETTY_FUNCTION__);
		
		if (!operation.hasAcceptableStatusCode) {
			[[NSNotificationCenter defaultCenter] postNotificationName:TSUserDidFailForgotPasswordNotification object:nil];
		} else {
			[[NSNotificationCenter defaultCenter] postNotificationName:TSUserDidFinishForgotPasswordNotification object:nil]; // Can add userinfo here if necessart=y
		}
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		[[NSNotificationCenter defaultCenter] postNotificationName:TSUserDidFailForgotPasswordNotification object:nil]; // Can add userinfo here if necessary
	}];
}

- (void)logout
{
	[self setUserDefaultsWithEmail:nil password:nil token:nil];
 
	[[NSNotificationCenter defaultCenter] postNotificationName:TSUserDidLogoutNotification object:self];
}

@end