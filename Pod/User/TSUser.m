//
//  TSUser.m
//
//  Created by Mark McFarlane on 27/05/2015.
//  Copyright (c) 2015 Tacchi Studios. All rights reserved.
//

#import "TSUser.h"
#import <TSRestkitManager.h>
#import "UIAlertController+Window.h"
#import "TSUserConfirmSharedLoginViewController.h"

#define LS(s) NSLocalizedString(s, nil)
#define TSLocalizedStringAccountCreationFailed LS(@"Account creation failed.")
#define TSLocalizedStringIncorrectEmailOrPassword LS(@"Incorrect email or password")

NSString * const TSUserDidStartLoginNotification				= @"TSUserDidStartLoginNotification";
NSString * const TSUserDidLoginNotification						= @"TSUserDidLoginNotification";
NSString * const TSUserDidFailLoginNotification					= @"TSUserDidFailLoginNotification";

NSString * const TSUserWillLogoutNotification					= @"TSUserWillLogoutNotification";
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

NSString * const TSUserDidStartExchangingTokenNotification		= @"TSUserDidStartExchangingTokenNotification";
NSString * const TSUserDidFailExchangingTokenNotification		= @"TSUserDidFailExchangingTokenNotification";

NSString * const TSUserWasLoggedOutDueToAuthError				= @"TSUserWasLoggedOutDueToAuthError";
NSString * const TSUserWasLoggedOutDueToNoServerConnectionForExtendedPeriod	= @"TSUserWasLoggedOutDueToNoServerConnectionForExtendedPeriod";

extern NSString * const TSUserWillShowSharedLoginViewController = @"TSUserWillShowSharedLoginViewController";

NSString * const OAUTH_TOKEN		= @"oauth_token";
NSString * const EMAIL				= @"email_address";
NSString * const PASSWORD			= @"password";

NSString * const APP_NAME				= @"app_name";
NSString * const KEYCHAIN_TOKEN_KEY		= @"keychain_oauth_token";
NSString * const KEYCHAIN_SERVICE		= @"ts_user_keychain_service";	// Not entirely sure why yet, but without this, the shared keychain doesn't work.


@interface TSUser()

@property (nonatomic) BOOL allowsAnonymousSessions;
@property (nonatomic, copy, nullable) NSString *anonymousSessionPath, *anonymousSessionUsername, *anonymousSessionPassword;
@property (nonatomic, copy, nullable) NSString *clientId, *clientSecret;

@end


@implementation TSUser

#pragma mark -
#pragma mark Singleton

+ (nonnull instancetype)sharedTSUser
{
	static dispatch_once_t once;
	static id sharedInstance;
	dispatch_once(&once, ^{
		sharedInstance = [[self alloc] init];
	});
	return sharedInstance;
}

#pragma mark -
#pragma mark Getters

- (nullable NSString *)email
{
	return self.storage.email;
}

- (BOOL)isLoggedIn
{
	if (self.allowsAnonymousSessions) {
		// Anonymous logins will always have an oAuth token, so we need to check that the email address exists in this case.
		return [self.storage token].length > 0 && self.storage.email.length > 0;
	}
	
	return [self.storage token].length > 0;
}

- (BOOL)isAnonymousSession
{
	return ![self isLoggedIn] && self.allowsAnonymousSessions;
}

- (BOOL)userShouldConfirmSharedLogin
{
	return [self.storage respondsToSelector:@selector(userShouldConfirmSharedLogin)] && [self.storage userShouldConfirmSharedLogin];
}

- (void)setStorage:(id<TSUserStorage>)storage
{
	_storage = storage;
	
	// Do this so we can have the auth header setup immediately if it's present.
	[self setRestkitAuthHeader:[storage token]];
}

#pragma mark -
#pragma mark Oauth setup

- (void)setRestkitAuthHeader:(NSString *)token
{
	NSLog(@"Setting up oauth token header: %@ - %s", token,__PRETTY_FUNCTION__);
	[[RKObjectManager sharedManager].HTTPClient setDefaultHeader:@"Authorization" value:token ? [NSString stringWithFormat:@"Bearer %@", token] : nil];
}

- (void)setupAuthHeader
{
	NSString *oAuthToken = [self.storage token];
	
	// We do this here, as if we don't have an oauth token we'll want to ensure it's not in the HTTPClient (i.e. if the app is being resumed after another app logged out all accounts etc.
	[self setRestkitAuthHeader:oAuthToken];
	
	if (oAuthToken) {
		// Check if the user has an anonymous oauth token already, but has since logged into another SL app and has a valid oAuth token for that app.
		if (self.allowsAnonymousSessions && ![self isLoggedIn] && self.sharedKeychainExchangeForAnonymousConnectionPath) {
			NSDictionary *token = [self.storage tokenDetailsForSharedKeychainSeparatedAppsThatCanBeExchangedForTokenForCurrentApp].anyObject; // It should just be any, as they're all for the same account!
			
			if (token) {
				[self performSharedLoginWithToken:token confirmation:^{
					[self connectThisAnonymousSessionToTokensUser:token];
				}];
			}
		}
	} else {
		NSLog(@"%@ - %s",@"Not logged in or session not present so not setting up oAuth token",__PRETTY_FUNCTION__);
		
		NSDictionary *token;
		
		if ([self.storage respondsToSelector:@selector(tokenDetailsForSharedKeychainSeparatedAppsThatCanBeExchangedForTokenForCurrentApp)]) {
			// If we're using credential separation for exchange, but you can't be logged into multiple accounts, let's exchange for a token for this app!
			token = [self.storage tokenDetailsForSharedKeychainSeparatedAppsThatCanBeExchangedForTokenForCurrentApp].anyObject; // It should just be any, as they're all for the same account!
		}
		
		if (token) {
			[self performSharedLoginWithToken:token confirmation:^{
				[self exchangeTokenFromOtherAppInSharedKeychainAccessGroup:token];
			}];
		} else if (self.allowsAnonymousSessions) {
			[self createAnonymousSession];
		} else {
			// Do nothing, as the user needs to log in.
		}
	}
}

- (UIViewController *)presentingViewController
{
	UIViewController *presentingViewController = UIApplication.sharedApplication.delegate.window.rootViewController;
	if (presentingViewController.presentedViewController) {
		presentingViewController = presentingViewController.presentedViewController;
	}
	
	return presentingViewController;
}

- (void)performSharedLoginWithToken:(NSDictionary *)token confirmation:(void (^)(void))confirmBlock
{
	if ([self userShouldConfirmSharedLogin]) {
		NSBundle *bundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"TSUser" ofType:@"bundle"]];
		if (!bundle) { // In case the app's podfile is using !use_frameworks
			bundle = [NSBundle bundleWithPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Frameworks/TSRestkitManager.framework/TSUser.bundle"]];
		}
		
		// Because we don't want to show it twice!
		if (![[self presentingViewController] isKindOfClass:[TSUserConfirmSharedLoginViewController class]]) {
			// In case any view controllers (e.g. profile) want to dismiss themselves before we present the confirm vc
			[[NSNotificationCenter defaultCenter] postNotificationName:TSUserWillShowSharedLoginViewController object:nil];
			
			// We use dispatch_after in case a view controller is being dismissed as a result of the above notification
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
				// We get a new reference to the presenting view controller here in case it was dismissed as a result of the above notification
				TSUserConfirmSharedLoginViewController *vc = [[UIStoryboard storyboardWithName:@"TSUser" bundle:bundle] instantiateViewControllerWithIdentifier:@"confirmSharedLogin"];
				[vc setConfirmBlock:confirmBlock];
				[vc setLoggedInEmail:token[EMAIL]];
				NSLog(@"%@ - %s",[self presentingViewController],__PRETTY_FUNCTION__);
				[[self presentingViewController] presentViewController:vc animated:YES completion:^{}];
			});

		}
	} else {
		confirmBlock();
	}
}

- (void)setClientId:(nonnull NSString *)clientId secret:(nonnull NSString *)clientSecret
{
	self.clientId = clientId;
	self.clientSecret = clientSecret;
}

- (void)enableAnonymousSessionsWithPath:(nonnull NSString *)path username:(nonnull NSString *)username password:(nonnull NSString *)password
{
	self.allowsAnonymousSessions = YES;
	
	self.anonymousSessionPath = path;
	self.anonymousSessionUsername = username;
	self.anonymousSessionPassword = password;
}

#pragma mark -
#pragma mark Login methods

- (void)createAnonymousSession
{
	if (!self.allowsAnonymousSessions) {
		[NSException raise:NSInternalInconsistencyException format:@"createAnonymousSession was called on TSUser but enableAnonymousSessionsWithPath:username:password:clientID:secret has not been called"];
	}
	
	// If session exists, ignore this
	if ([self.storage token]) {
		NSLog(@"%@ - %s",@"createAnonymousSession was called but we already have a session token",__PRETTY_FUNCTION__);
		return;
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:TSUserDidStartGettingSessionTokenNotification object:nil];
	
	self.anonymousSessionUsername = [self.anonymousSessionUsername stringByReplacingOccurrencesOfString:@"&" withString:@"%26"]; // We need to escape out any ampersands in the username (e.g. 'l&r')
	
	
	NSString *httpBody = [NSString stringWithFormat:@"client_id=%@&client_secret=%@&username=%@&password=%@&grant_type=password", self.clientId, self.clientSecret, self.anonymousSessionUsername, self.anonymousSessionPassword];
	
	NSString *urlString = self.anonymousSessionPath;
	NSMutableURLRequest *request = [[RKObjectManager sharedManager].HTTPClient requestWithMethod:@"POST" path:urlString parameters:nil];
	[request setHTTPBody:[httpBody dataUsingEncoding:NSUTF8StringEncoding]];
	
	AFRKHTTPRequestOperation *operation = [[AFRKHTTPRequestOperation alloc] initWithRequest:request];
	[operation setCompletionBlockWithSuccess:^(AFRKHTTPRequestOperation *operation, id responseObject) {
		NSLog(@"Did load response - %@ - %s",operation.responseString,__PRETTY_FUNCTION__);
		
		if (operation.hasAcceptableStatusCode) {
			NSDictionary *parsedResponse = [NSJSONSerialization JSONObjectWithData:operation.responseData options:0 error:nil]; // operation.responseData == responseObject
			
			NSString *accessToken = [parsedResponse objectForKey:@"access_token"];
			
			[self.storage setToken:accessToken email:nil password:nil];
			[self setupAuthHeader];
			
			[[NSNotificationCenter defaultCenter] postNotificationName:TSUserDidGetSessionTokenNotification object:nil];
		} else {
			[self handleAnonymousSessionFailed];
		}
	} failure:^(AFRKHTTPRequestOperation *operation, NSError *error) {
		NSLog(@"Error: %@", error);
		[self handleAnonymousSessionFailed];
	}];
	[operation start];
}

- (void)handleAnonymousSessionFailed
{
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:LS(@"tsuser.anonymoussession.fail.title") message:LS(@"tsuser.anonymoussession.fail.message") preferredStyle:UIAlertControllerStyleAlert];
	[alert addAction:[UIAlertAction actionWithTitle:LS(@"Retry") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		[self createAnonymousSession];
	}]];
	[alert show];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:TSUserDidFailGettingSessionTokenNotification object:nil];
}

- (void)loginWithEmail:(nonnull NSString *)email password:(nonnull NSString *)password
{
	if (self.allowsAnonymousSessions) {
		NSAssert([self.storage token], @"MUST HAVE A SESSION OAUTH TOKEN");
		
		if (!self.storage.token.length) {
			[NSException raise:NSInternalInconsistencyException format:@"loginWithEmail:password was called but there's no session token"];
		}
		
		if (!self.sessionUserConnectionPath.length) {
			[NSException raise:NSInternalInconsistencyException format:@"loginWithEmail:password was called with allowsAnonymousSessions, but sessionUserConnectionPath hasn't been set"];
		}
		
		if (self.loginPath.length) {
			[NSException raise:NSInternalInconsistencyException format:@"loginWithEmail:password was called with allowsAnonymousSessions, but loginPath has been set. Please do not set loginPath at the same time as allowsAnonymousSessions"];
		}
		
		[[NSNotificationCenter defaultCenter] postNotificationName:TSUserDidStartLoginNotification object:nil userInfo:nil];

		[[[RKObjectManager sharedManager] HTTPClient] postPath:self.sessionUserConnectionPath parameters:@{@"username": email, @"password": password} success:^(AFRKHTTPRequestOperation *operation, id responseObject) {
			
			[self handleLoginWithAnonymousSessionWithResponseObject:responseObject email:email password:password];
			
		} failure:^(AFRKHTTPRequestOperation *operation, NSError *error) {
			NSLog(@"%@ - %s",error.localizedDescription,__PRETTY_FUNCTION__);

			[self handleLoginError:error response:operation];
		}];
	} else {
		[[NSNotificationCenter defaultCenter] postNotificationName:TSUserDidStartLoginNotification object:nil userInfo:nil];

		email = [email stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"]; // + doesn't get URL escaped so we do this. Another option could be to use CFURLCreateStringByAddingPercentEscapes, but that may be overkill
		
		NSString *httpBody = [NSString stringWithFormat:@"client_id=%@&client_secret=%@&username=%@&password=%@&grant_type=password", self.clientId, self.clientSecret, email, password];
		#warning Can remove the format here and just tell to use a / if needed?
		NSString *urlString = [NSString stringWithFormat:@"%@/%@", self.baseURL, self.loginPath];
		
		NSMutableURLRequest *request = [[RKObjectManager sharedManager].HTTPClient requestWithMethod:@"POST" path:urlString parameters:nil];
		[request setHTTPBody:[httpBody dataUsingEncoding:NSUTF8StringEncoding]];
		
		AFRKHTTPRequestOperation *operation = [[AFRKHTTPRequestOperation alloc] initWithRequest:request];
		[operation setCompletionBlockWithSuccess:^(AFRKHTTPRequestOperation *operation, id responseObject) {
			NSLog(@"Did load response - %@ - %s",operation.responseString,__PRETTY_FUNCTION__);
			
			if (operation.hasAcceptableStatusCode) {
				NSDictionary *parsedResponse = [NSJSONSerialization JSONObjectWithData:operation.responseData options:0 error:nil]; // operation.responseData == responseObject
				
				NSString *accessToken = [parsedResponse objectForKey:@"access_token"];
				
				[self handleSuccessfulLoginWithEmail:email password:password token:accessToken];
			} else {
				[self handleLoginError:nil response:operation];
			}
		} failure:^(AFRKHTTPRequestOperation *operation, NSError *error) {
			[self handleLoginError:error response:operation];
		}];
		[operation start];
	}
}

- (void)handleSuccessfulLoginWithEmail:(nonnull NSString *)email password:(nonnull NSString *)password token:(nonnull NSString *)accessToken
{
	if (self.spoofAccessToken) {
		accessToken = self.spoofAccessToken;
	}
	
	[self.storage setToken:accessToken email:email password:password];
	[self setupAuthHeader];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:TSUserDidLoginNotification object:nil];
}

- (void)handleLoginWithAnonymousSessionWithResponseObject:(id)responseObject email:(NSString *)email password:(NSString *)password
{
	// Check meta key path and act accordingly
	// account_linked | account_creation_failed
	
	NSAssert([responseObject isKindOfClass:[NSDictionary class]], @"THIS SHOULD BE A DICTIONARY!");
	
	NSString *linkStatus = [[responseObject objectForKey:@"meta"] objectForKey:@"status"];
	NSDictionary *userDict = [responseObject objectForKey:@"user"];
	
	if ([linkStatus isEqualToString:@"account_linked"]) {
		NSLog(@"account_linked - Got USER! %@ - %s",userDict,__PRETTY_FUNCTION__);

		[self.storage setToken:self.storage.token email:email password:password];
		[self setupAuthHeader];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:TSUserDidLoginNotification object:userDict];
	} else if ([linkStatus isEqualToString:@"account_creation_failed"]) {
		NSString *message = [[[responseObject objectForKey:@"ec_cube"] objectForKey:@"error_details"] lastObject];
		[[NSNotificationCenter defaultCenter] postNotificationName:TSUserDidFailCreatingAccountNotification object:message];
	} else {
		NSLog(@"%@ - %s",@"hmm, no known link status",__PRETTY_FUNCTION__);
	}
}

- (void)handleLoginError:(NSError *)error response:(AFRKHTTPRequestOperation *)operation
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
				case 401:
					message = TSLocalizedStringIncorrectEmailOrPassword;
					break;
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
			message = NSLocalizedString(@"Your device is not connected to the Internet.", nil);
		}
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:TSUserDidFailLoginNotification object:message];
}

#pragma mark -
#pragma mark Forgot password methods

- (void)forgotPasswordForUserParams:(nonnull NSDictionary *)params
{
	[[NSNotificationCenter defaultCenter] postNotificationName:TSUserDidStartForgotPasswordNotification object:nil];
	
	[[RKObjectManager sharedManager].HTTPClient postPath:self.forgotPasswordPath parameters:params success:^(AFRKHTTPRequestOperation *operation, id responseObject) {
		NSLog(@"%@ - %s",operation.responseString,__PRETTY_FUNCTION__);
		
		if (!operation.hasAcceptableStatusCode) {
			[[NSNotificationCenter defaultCenter] postNotificationName:TSUserDidFailForgotPasswordNotification object:nil];
		} else {
			[[NSNotificationCenter defaultCenter] postNotificationName:TSUserDidFinishForgotPasswordNotification object:nil]; // Can add userinfo here if necessart=y
		}
	} failure:^(AFRKHTTPRequestOperation *operation, NSError *error) {
		[[NSNotificationCenter defaultCenter] postNotificationName:TSUserDidFailForgotPasswordNotification object:nil]; // Can add userinfo here if necessary
	}];
}

#pragma mark -
#pragma mark Logout methods

- (void)logoutFrom:(nonnull UIViewController *)viewController
{
	[self logoutFrom:viewController dismissBefore:NO];
}

- (void)logoutFrom:(nonnull UIViewController *)viewController dismissBefore:(BOOL)dismissBefore
{	
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"tsuser.logout.title", nil)
																   message:NSLocalizedString(@"tsuser.logout.message", nil)
															preferredStyle:UIAlertControllerStyleAlert];

	UIAlertAction *logoutAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"tsuser.logout.logoutaction.title", nil)
														   style:UIAlertActionStyleDestructive
														 handler:^(UIAlertAction *action) {
															 if (dismissBefore) {
																 [viewController dismissViewControllerAnimated:YES completion:^{
																	 [self logout];
																 }];
															 } else {
																 [self logout];
															 }
														 }];
	[alert addAction:logoutAction];
	[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"tsuser.logout.cancelaction.title", nil) style:UIAlertActionStyleCancel handler:nil]];
	[viewController presentViewController:alert animated:YES completion:nil];
}

- (void)logout
{
	BOOL initiallyLoggedIn = [self isLoggedIn];
	if (initiallyLoggedIn) {
		[[NSNotificationCenter defaultCenter] postNotificationName:TSUserWillLogoutNotification object:self];
	}
	
	[self.storage setToken:nil email:nil password:nil];
	[self setupAuthHeader]; // Basically clear out the current auth header as it's now nil. This will create a new anonymous session if needed.
	
	if (initiallyLoggedIn) {
		[[NSNotificationCenter defaultCenter] postNotificationName:TSUserDidLogoutNotification object:self];
	}
}

- (void)logoutDueToAuthError
{
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"アカウントはログアウトされました。" message:@"ご利用可能な端末制限数を超えています。お使いの端末をご確認いただきログインをお試しください。" preferredStyle:UIAlertControllerStyleAlert];
	[alert addAction:[UIAlertAction actionWithTitle:@"閉じる" style:UIAlertActionStyleCancel handler:nil]];
	[alert show];
	
    [self logout];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:TSUserWasLoggedOutDueToAuthError object:self];
}

- (void)logoutDueToNoServerConnectionForExtendedPeriod
{
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"アカウントはログアウトされました。" message:@"ご利用可能な端末制限数を超えています。お使いの端末をご確認いただきログインをお試しください。" preferredStyle:UIAlertControllerStyleAlert];
	[alert addAction:[UIAlertAction actionWithTitle:@"閉じる" style:UIAlertActionStyleCancel handler:nil]];
	[alert show];
	
	[self logout];

	[[NSNotificationCenter defaultCenter] postNotificationName:TSUserWasLoggedOutDueToNoServerConnectionForExtendedPeriod object:self];
}



+ (BOOL)emailIsValid:(nonnull NSString *)email
{
	BOOL stricterFilter = NO; // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
	NSString *stricterFilterString = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
	NSString *laxString = @".+@.+\\.[A-Za-z]{2}[A-Za-z]*";
	NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
	NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
	return [emailTest evaluateWithObject:email];
}

- (void)registerNewUserWithUser:(nonnull TSCreateAccountUser *)user
{
	NSAssert([self.class emailIsValid:user.email], @"Shouldn't get here without a valid email!");
	NSAssert(user.password.length > 0, @"Need a password!");
	
	NSDictionary *params = @{@"user": @{@"email": user.email, @"password": user.password, @"last_name": user.surname, @"first_name": user.firstName}};
	
	#warning Create account path?
	[[[RKObjectManager sharedManager] HTTPClient] postPath:@"user" parameters:params success:^(AFRKHTTPRequestOperation *operation, id responseObject) {
		NSLog(@"Success - %@ - %s",responseObject,__PRETTY_FUNCTION__);
		[self loginWithEmail:user.email password:user.password];
	} failure:^(AFRKHTTPRequestOperation *operation, NSError *error) {
		NSLog(@"Error - %@ - %s",error.localizedDescription,__PRETTY_FUNCTION__);

		[[NSNotificationCenter defaultCenter] postNotificationName:TSUserDidFailCreatingAccountNotification object:error.localizedDescription userInfo:nil];
	}];
}

#pragma mark -
#pragma mark Exchange methods

// Accepts a token from another app
// Exchanges it for a token for this app

- (void)exchangeTokenFromOtherAppInSharedKeychainAccessGroup:(nonnull NSDictionary *)token
{
	
	NSLog(@"token: %@ - %s",token,__PRETTY_FUNCTION__);
	NSLog(@"clientId: %@ - %s",self.clientId,__PRETTY_FUNCTION__);

	if (!self.clientId) {
		[NSException raise:NSInternalInconsistencyException format:@"exchangeTokenFromOtherAppInSharedKeychainAccessGroup was called but self.clientId hasn't been set."];
	}
	if (!self.sharedKeychainExchangePath) {
		[NSException raise:NSInternalInconsistencyException format:@"exchangeTokenFromOtherAppInSharedKeychainAccessGroup was called but enableSharedKeychainCredentialSeparationForExchangeWithPath: has not been called yet."];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:TSUserDidStartLoginNotification object:nil userInfo:nil];
	
	NSLog(@"Exchanging token: %@, headers: %@ - %s",token, [RKObjectManager sharedManager].HTTPClient.defaultHeaders,__PRETTY_FUNCTION__);
	
	[[[RKObjectManager sharedManager] HTTPClient] postPath:self.sharedKeychainExchangePath parameters:@{@"application_uid" : self.clientId, @"access_token" : token[OAUTH_TOKEN]} success:^(AFRKHTTPRequestOperation *operation, id responseObject) {
		NSLog(@"Success - %@ - %s",responseObject,__PRETTY_FUNCTION__);

		// Possibly send out a notification for Exchanged here? Althogh didLogin is sent out in the below call
		[self handleSuccessfulLoginWithEmail:token[EMAIL] password:token[PASSWORD] token:responseObject[@"token"]];
		
	} failure:^(AFRKHTTPRequestOperation *operation, NSError *error) {
		[self handleSharedLoginFailure:operation];

		if (self.allowsAnonymousSessions) {
			[self createAnonymousSession];
		}
	}];
}

// Accepts a token from another app
// Asks the server to link the token's user to this anonymous session
- (void)connectThisAnonymousSessionToTokensUser:(nonnull NSDictionary *)token
{
	NSLog(@"%@ - %s",token,__PRETTY_FUNCTION__);
	
	if (!self.sharedKeychainExchangeForAnonymousConnectionPath) {
		[NSException raise:NSInternalInconsistencyException format:@"connectThisAnonymousSessionToTokensUser was called but sharedKeychainExchangeForAnonymousConnectionPath has not been set yet."];
	}
	if (!self.allowsAnonymousSessions) {
		[NSException raise:NSInternalInconsistencyException format:@"connectThisAnonymousSessionToTokensUser was called but enableAnonymousSessionsWithPath:username:password has not been called yet."];
	}
	
	[[[RKObjectManager sharedManager] HTTPClient] putPath:self.sharedKeychainExchangeForAnonymousConnectionPath parameters:@{@"source_access_token" : token[OAUTH_TOKEN]} success:^(AFRKHTTPRequestOperation *operation, id responseObject) {
		NSLog(@"Success - %@ - %s",responseObject,__PRETTY_FUNCTION__);
		
		[self handleSuccessfulLoginWithEmail:token[EMAIL] password:[self.storage password] token:[self.storage token]];
		
	} failure:^(AFRKHTTPRequestOperation *operation, NSError *error) {
		[self handleSharedLoginFailure:operation];
	}];
}

- (void)handleSharedLoginFailure:(AFRKHTTPRequestOperation *)operation
{
	NSLog(@"Error - %@ - %s",operation.error.localizedDescription,__PRETTY_FUNCTION__);
	NSLog(@"Error - %@ - %s",operation.request.URL.absoluteString,__PRETTY_FUNCTION__);
	
	[[NSNotificationCenter defaultCenter] postNotificationName:TSUserDidFailExchangingTokenNotification object:operation userInfo:nil];
}

@end



@implementation TSCreateAccountUser

@end

