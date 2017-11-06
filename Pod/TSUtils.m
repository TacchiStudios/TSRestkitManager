//
//  TSUtils.h
//
//  Created by Mark McFarlane on 17/03/2015.
//  Copyright (c) 2017 Tacchi Studios. All rights reserved.
//

#import "TSUtils.h"
#import <sys/utsname.h>
#import "NSDate+Helper.h"

@implementation TSUtils


+ (NSString *)versionString
{
	NSString *versionString = [NSString stringWithFormat:@"v%@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
	return versionString;
}

+ (NSString *)versionStringWithBundleVersion
{
	NSString *compileDate = [NSString stringWithUTF8String:__DATE__];
	NSDateFormatter *df = [[NSDateFormatter alloc] init];
	[df setDateFormat:@"MMM d yyyy"];
	NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
	[df setLocale:usLocale];
	NSDate *aDate = [df dateFromString:compileDate];
	
	NSString *versionString = [NSString stringWithFormat:@"%@ (%@) %@", [self versionString], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"], [aDate stringWithDateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle]];

	return versionString;
}

+ (NSString*)deviceName
{
	struct utsname systemInfo;
	uname(&systemInfo);
	
	return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}

+ (NSString *)deviceDetailsString
{
	return [NSString stringWithFormat:@"device-model: %@, os-version: %@, app-version: %@", [self deviceName] , [[UIDevice currentDevice] systemVersion], [NSString stringWithFormat:@"v%@ (%@)", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]]];
}

@end
