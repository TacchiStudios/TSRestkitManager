//
//  TSUser.h
//
//  Created by Mark McFarlane on 27/05/2015.
//  Copyright (c) 2015 Tacchi Studios. All rights reserved.
//

// Notifications

NS_ASSUME_NONNULL_BEGIN
extern NSString * const TSUserDidStartLoginNotification;
extern NSString * const TSUserDidLoginNotification;			// Provides a dictionary about the user as the notification object if exists
extern NSString * const TSUserDidFailLoginNotification;

extern NSString * const TSUserWillLogoutNotification;		// Use this if you want to do any cleanup that requires the user's email address etc before it's all cleared out
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

extern NSString * const TSUserDidStartExchangingTokenNotification; // TSUserDidLoginNotification will be called after this if sucessful.
extern NSString * const TSUserDidFailExchangingTokenNotification;

extern NSString * const TSUserWasLoggedOutDueToAuthError;
extern NSString * const TSUserWasLoggedOutDueToNoServerConnectionForExtendedPeriod;

extern NSString * const OAUTH_TOKEN;
extern NSString * const EMAIL;
extern NSString * const PASSWORD;

extern NSString * const APP_NAME;
extern NSString * const KEYCHAIN_TOKEN_KEY;
extern NSString * const KEYCHAIN_SERVICE;
NS_ASSUME_NONNULL_END


@protocol TSUserStorage <NSObject>
@required
- (void)setToken:(nullable NSString *)token email:(nullable NSString *)email password:(nullable NSString *)password;
- (nullable NSString *)token;
- (nullable NSString *)email;
- (nullable NSString *)password;
@optional
- (nullable NSSet<NSDictionary *> *)tokenDetailsForSharedKeychainSeparatedAppsThatCanBeExchangedForTokenForCurrentApp; // Only for apps that allow shared keychain storage (e.g. TSSharedKeychainPerAppStorage)
@end

@class TSCreateAccountUser;											// Forward declaration of below


@interface TSUser : NSObject

@property (nonatomic, strong, nonnull) id<TSUserStorage> storage;

@property (nonatomic, copy, nonnull) NSString *baseURL;						// Would prefer to get this from RestKit, but for now it needs to not include api version path component.
@property (nonatomic, copy, nullable) NSString *loginPath;					// Appended to the baseURL and / to create the absolute path for login. E.g. @"oauth/token"
@property (nonatomic, copy, nullable) NSString *sessionUserConnectionPath;	// The path to call when logging in while already having an anonymous session. This just needs to be the resource path, no base URL needed as it's taken from RK
@property (nonatomic, copy, nullable) NSString *sharedKeychainExchangePath;
@property (nonatomic, copy, nullable) NSString *sharedKeychainExchangeForAnonymousConnectionPath; // The path to call when linking an account to an anonymous session using an oAuth token from another app in the same shared keychain access group. This just needs to be the resource path, no base URL needed as it's taken from RK

@property (nonatomic, copy, nullable) NSString *forgotPasswordPath;			// The path to call when requesting a password reset

@property (nonatomic, copy, nullable) NSString *spoofAccessToken;			// Use this to spoof in an oAuth access token for debug purposes.

+ (nonnull instancetype)sharedTSUser;


- (void)setClientId:(nonnull NSString *)clientId secret:(nonnull NSString *)clientSecret;
- (void)enableAnonymousSessionsWithPath:(nonnull NSString *)path username:(nonnull NSString *)username password:(nonnull NSString *)password;

- (BOOL)isLoggedIn;					// User is logged in and we have their email address. This will return NO if an anonymous session token exists, but the user is not logged in.
- (nullable NSString *)email;		// Logged in user's email address.

- (void)createAnonymousSession;		// Requires enableAnonymousSessionsWithPath:username:password to be called first

- (void)loginWithEmail:(nonnull NSString *)username password:(nonnull NSString *)password;	// If anonymous sessions are enabled, will attach the user's account to their session. If non anon sessions, will start the usual oAuth2 flow.
- (void)logoutDueToAuthError;												// If we get a 401 back from a request we should call this to logout the user.
- (void)logoutDueToNoServerConnectionForExtendedPeriod;						// Call this in situations where a user has not run the app while connected to the internet for a certina period. e.g. to stop access to downloaded contents.
- (void)logout;																// Destroy the login or anonymous session. If anon sessions enabled, create a new one automatically.

- (void)setupAuthHeader;													// Setup the header for TSRestkitManager to use in its requests. Generally you'd do this after setting up TSRestkitManager, usually in applicationDidBecomeActive. Make sure you call this this last, after setting all other options!

- (void)forgotPasswordForUserParams:(nonnull NSDictionary *)params;			// Params get passed to the request directly, so put whatever your server is expecting in here (e.g. just email, or email + name + DOB etc).

+ (BOOL)emailIsValid:(nonnull NSString *)email;

- (void)registerNewUserWithUser:(nonnull TSCreateAccountUser *)user;

@end



#define TSCreateAccountUserGenderMale @"m"
#define TSCreateAccountUserGenderFemale @"f"

@interface TSCreateAccountUser : NSObject

@property (nonatomic, strong, nullable) NSString *email, *password, *firstName, *surname, *gender;
@property (nonatomic, strong, nullable) NSDate *DOB;

@end
