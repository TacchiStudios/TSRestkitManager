//
//  TSSharedKeychainStorage.h
//  Pods
//
//  Created by Mark McFarlane on 08/02/2017.
//
//

#import <Foundation/Foundation.h>
#import "TSUser.h"

// Use this to have one oAuth token which will work across multiple apps in the same group
@interface TSSharedKeychainStorage : NSObject <TSUserStorage>

@property (nonatomic, copy, nonnull) NSString *accessGroup;			// Store the credentials in a shared keychain group so that the data can be shared between applications in the same group. This is for SSO.

@end
