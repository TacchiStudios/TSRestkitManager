//
//  TSSharedKeychainPerAppStorage.h
//  Pods
//
//  Created by Mark McFarlane on 08/02/2017.
//
//

#import <Foundation/Foundation.h>
#import "TSUser.h"

extern NSString * const TSUserDidLogoutAllAppsNotification;

@interface TSSharedKeychainPerAppStorage : NSObject <TSUserStorage>

// Use this if you have separate oAuth clients that must have separate tokens. Likely you'll use this with token exchange, or to show login status of other apps for some reason.
@property (nonatomic, copy, nonnull) NSString *accessGroup;			// Store the credentials in a shared keychain group so that the data can be shared between applications in the same group. This is for SSO.
@property BOOL userShouldConfirmSharedLogin;

@end
