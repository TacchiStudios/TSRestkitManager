//
//  TSUser.h
//
//  Created by Mark McFarlane on 27/05/2015.
//  Copyright (c) 2015 Tacchi Studios. All rights reserved.
//

// Notifications

extern NSString * const TSUserDidStartLoginNotification;
extern NSString * const TSUserDidLoginNotification;
extern NSString * const TSUserDidFailLoginNotification;

extern NSString * const TSUserDidLogoutNotification;

extern NSString * const TSUserDidStartGettingSessionTokenNotification;
extern NSString * const TSUserDidGetSessionTokenNotification;
extern NSString * const TSUserDidFailGettingSessionTokenNotification;

extern NSString * const TSUserDidStartCreatingAccountNotification;
extern NSString * const TSUserDidCreateAccountNotification;
extern NSString * const TSUserDidFailCreatingAccountNotification;

extern NSString * const TSUserDidStartUpdatingUserDetailsNotification;
extern NSString * const TSUserDidUpdateUserDetailsNotification;
extern NSString * const TSUserDidFailUpdatingUserDetailsNotification;

extern NSString * const TSUserDidStartForgotPasswordNotification;
extern NSString * const TSUserDidFinishForgotPasswordNotification;
extern NSString * const TSUserDidFailForgotPasswordNotification;


typedef enum {
	TSUserLoginTypeNotLoggedIn = 0,
	TSUserLoginTypeAnonymousSession,
	TSUserLoginTypeRegisteredUser
} TSUserLoginType;


@interface TSUser : NSObject

@property (nonatomic, copy) NSString *baseURL;						// Would prefer to get this from RestKit, but for now it needs to not include api version path component.
@property (nonatomic, copy) NSString *loginPath;					// Appended to the baseURL and / to create the absolute path for login. E.g. @"oauth/token"
@property (nonatomic, copy) NSString *sessionUserConnectionPath;	// The path to call when logging in while already having an anonymous session。This just needs to be the resource path, no base URL needed as it's taken from RK
@property (nonatomic, copy) NSString *forgotPasswordPath;			// The path to call when requesting a password reset

@property (nonatomic, copy) NSString *spoofAccessToken;				// Use this to spoof in an access token for debug purposes.

+ (instancetype)sharedTSUser;


- (void)setClientId:(NSString *)clientId secret:(NSString *)clientSecret;
- (void)enableAnonymousSessionsWithPath:(NSString *)path username:(NSString *)username password:(NSString *)password;

- (BOOL)hasSessionToken;	// Has an anonymous session running.
- (BOOL)isLoggedIn;			// User is logged in and we have their email address.
- (NSString *)email;		// Logged in user's email address.
- (NSString *)oAuthToken;

- (void)loginWithEmail:(NSString *)username password:(NSString *)password;	// If anonymous sessions are enabled, will attach the user's account to their session. If non anon sessions, will start the usual oAuth2 flow.
- (void)logoutDueToAuthError;												// If we get a 401 back from a request we should call this to logout the user.
- (void)logout;																// Destroy the login or anonymous session. If anon sessions enabled, create a new one automatically.

- (void)setupAuthHeader;													// Setup the header for TSRestkitManager to use in its requests.

- (void)forgotPasswordForUserParams:(NSDictionary *)params;

@end