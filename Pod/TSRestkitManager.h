//
//  TSRestkitManager.h
//  SpeedLearning
//
//  Created by Mark McFarlane on 25/03/2015.
//  Copyright (c) 2015 Espritline Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RestKit.h>
#import <AFNetworking.h>


// Needs SystemConfiguration

typedef enum _RKlcl_enum_level_t RKLogLevel;

@protocol TSRestKitMappableObject <NSObject>

@required

+ (RKEntityMapping *)entityMapping:(RKManagedObjectStore *)managedObjectStore;

@optional

+ (NSArray *)responseDescriptors:(RKManagedObjectStore *)managedObjectStore;
+ (NSArray *)requestDescriptors:(RKManagedObjectStore *)managedObjectStore;

@end


@interface TSRestkitManager : NSObject

+ (void)setupRestKitWithBaseURLString:(NSString *)baseURLString
			   managedObjectModelName:(NSString *)momdName
					 databaseFileName:(NSString *)databaseFileNameOrNil
			responseDescriptorClasses:(NSArray *)responseDescriptorClasses
			 requestDescriptorClasses:(NSArray *)requestDescriptorClasses;

+ (void)setReachabilityStatusChangeBlock:(void (^)(AFNetworkReachabilityStatus status))block;

+ (void)setNetworkLogLevel:(RKLogLevel)level;

+ (void)setObjectMappingLogLevel:(RKLogLevel)level;

+ (BOOL)isNetworkReachable;

// Returns the absolute path of the .sqlite file
+ (NSString *)persistentStorePath;

// Don't backup the .sqlite file to iCloud
+ (BOOL)addSkipBackupAttributeToPersistantStoreFile;

@end