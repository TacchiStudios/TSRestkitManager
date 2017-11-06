//
//  TSUtils.h
//
//  Created by Mark McFarlane on 17/03/2015.
//  Copyright (c) 2017 Tacchi Studios. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSUtils : NSObject

+ (NSString *)versionString;
+ (NSString *)versionStringWithBundleVersion;

+ (NSString *)deviceDetailsString;

@end
