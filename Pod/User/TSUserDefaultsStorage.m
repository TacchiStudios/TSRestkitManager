//
//  TSUserDefaultsStorage.m
//  Pods
//
//  Created by Mark McFarlane on 08/02/2017.
//
//

#import "TSUserDefaultsStorage.h"

@implementation TSUserDefaultsStorage

- (void)setToken:(NSString *)token email:(NSString *)email password:(NSString *)password
{
	[[NSUserDefaults standardUserDefaults] setObject:token forKey:OAUTH_TOKEN];
	[[NSUserDefaults standardUserDefaults] setObject:email forKey:EMAIL];
	[[NSUserDefaults standardUserDefaults] setObject:password forKey:PASSWORD];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

@end
