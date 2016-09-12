//
//  TSRestkitManager.m
//
//  Created by Mark McFarlane on 25/03/2015.
//  Copyright (c) 2015 Tacchi Studios. All rights reserved.
//

#import "TSRestkitManager.h"
#import <sys/utsname.h>
#import "MagicalRecord.h"



@interface NSManagedObjectContext ()

+ (void) MR_setRootSavingContext:(NSManagedObjectContext *)context;
+ (void) MR_setDefaultContext:(NSManagedObjectContext *)context;

@end



@implementation TSRestkitManager

static NSString *databaseFileName;

+ (void)setupRestKitWithBaseURLString:(NSString *)baseURLString managedObjectModelName:(NSString *)momdName databaseFileName:(NSString *)databaseFileNameOrNil responseDescriptorClasses:(NSArray *)responseDescriptorClasses requestDescriptorClasses:(NSArray *)requestDescriptorClasses
{
	databaseFileName = databaseFileNameOrNil;
	
	NSError *error = nil;
	NSURL *modelURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:momdName ofType:@"momd"]];
	NSManagedObjectModel *managedObjectModel = [[[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL] mutableCopy];
	RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:managedObjectModel];
	[managedObjectStore createPersistentStoreCoordinator];
	
	
	NSPersistentStore __unused *persistentStore = [managedObjectStore addSQLitePersistentStoreAtPath:[self persistentStorePath] fromSeedDatabaseAtPath:nil withConfiguration:nil options:@{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES} error:&error];
	NSAssert(persistentStore, @"Failed to add persistent store: %@", error);
	
	[managedObjectStore createManagedObjectContexts];
	[RKManagedObjectStore setDefaultStore:managedObjectStore];
	
	
	RKObjectManager *objectManager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:baseURLString]];
	objectManager.managedObjectStore = managedObjectStore;
	[RKObjectManager setSharedManager:objectManager];
	
	
	for (Class<TSRestKitMappableObject> clazz in responseDescriptorClasses) {
		[objectManager addResponseDescriptorsFromArray:[clazz responseDescriptors:managedObjectStore]];
	}
	
	for (Class<TSRestKitMappableObject> clazz in requestDescriptorClasses) {
		[objectManager addRequestDescriptorsFromArray:[clazz requestDescriptors:managedObjectStore]];
	}
	
	// This is a nice addition that we can log on the server end to help with tracking bugs etc
	[[RKObjectManager sharedManager].HTTPClient setDefaultHeader:@"x-device-details" value:[self deviceDetailsString]];
	
	// Enabling the network activity indicator
	[AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
	
	[self setupMagicalRecord];
}

+ (void)setupMagicalRecord
{
	// Configure MagicalRecord to use RestKit's Core Data stack
	RKManagedObjectStore *managedObjectStore = [RKManagedObjectStore defaultStore];
	
	[NSPersistentStoreCoordinator MR_setDefaultStoreCoordinator:managedObjectStore.persistentStoreCoordinator];
	[NSManagedObjectContext MR_setRootSavingContext:managedObjectStore.persistentStoreManagedObjectContext];
	[NSManagedObjectContext MR_setDefaultContext:managedObjectStore.mainQueueManagedObjectContext];
}

+ (NSString *)deviceDetailsString
{
	NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
	return [NSString stringWithFormat:@"device-model: %@, os-version: %@, app-name: %@, app-version: %@", [self deviceName] , [[UIDevice currentDevice] systemVersion], [infoDict objectForKey:@"CFBundleIdentifier"], [NSString stringWithFormat:@"v%@ (%@)", [infoDict objectForKey:@"CFBundleShortVersionString"], [infoDict objectForKey:@"CFBundleVersion"]]];
}

+ (NSString*)deviceName
{
	struct utsname systemInfo;
	uname(&systemInfo);
	
	return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}

+ (void)setReachabilityStatusChangeBlock:(void (^)(AFNetworkReachabilityStatus status))block
{
	[[RKObjectManager sharedManager].HTTPClient setReachabilityStatusChangeBlock:block];
}

+ (void)setNetworkLogLevel:(RKLogLevel)level
{
	RKLogConfigureByName("RestKit/Network", level);
}

+ (void)setObjectMappingLogLevel:(RKLogLevel)level
{
	RKLogConfigureByName("RestKit/Network", level);
}

+ (BOOL)isNetworkReachable
{
	return [[RKObjectManager sharedManager].HTTPClient networkReachabilityStatus] != AFNetworkReachabilityStatusNotReachable;
}

+ (NSString *)persistentStorePath
{
	return [RKApplicationDataDirectory() stringByAppendingPathComponent:databaseFileName ? databaseFileName : @"db.sqlite"]; // We just hardcode this. Honestly doesn't really matter what the filename is.
}

// We don't support iOS 5 any more, so no need for the iOS 5.1 version of this.
+ (BOOL)addSkipBackupAttributeToPersistantStoreFile
{
	NSURL *URL = [NSURL URLWithString:[self persistentStorePath]];
	
	assert([[NSFileManager defaultManager] fileExistsAtPath:[URL path]]);
	
	NSError *error = nil;
	BOOL success = [URL setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:&error];
	if(!success){
		NSLog(@"Error excluding %@ from backup %@", [URL lastPathComponent], error);
	}
	return success;
}

+ (void)saveToPersistantStore
{
	// Saves changes in the application's managed object context before the application terminates.
	[[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
	
	// Saves changes in the application's managed object context before the application terminates.
	[MagicalRecord cleanUp];
}

@end
