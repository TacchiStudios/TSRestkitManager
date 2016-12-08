# TSRestkitManager

## About

A simple, quick, standardized way to get Restkit and MagicalRecord set up in your iOS project.

## Getting Started

Include the following line in your podfile (will get this on the core pods repo soon)
```ruby
pod 'TSRestkitManager', :git => 'https://github.com/TacchiStudios/TSRestkitManager.git', :tag => 'v0.1.0'
```

Import the header file
```Objective-C
#import <TSRestKitManager.h>
```

In your app delegate, setup the manager, feeding it a list of classes that adhere to the ```TSRestKitMappableObject``` protocol.

```Objective-C
NSArray *responseDescriptorClasses = @[[SLETopic class], [SLEResultGroup class]];
	
NSArray *requestDescriptorClasses = @[[SLEResultGroup class]];
	
[TSRestkitManager setupRestKitWithBaseURLString:@"https://www.myserver.com/api/v1"
						 managedObjectModelName:@"Model"
							   databaseFileName:@"db.sqlite"
					  responseDescriptorClasses:responseDescriptorClasses
					   requestDescriptorClasses:requestDescriptorClasses];
```

Where necessary, use additional options, e.g. (see header for more)

```
	[TSRestkitManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
		if (status == AFNetworkReachabilityStatusReachableViaWiFi || status == AFNetworkReachabilityStatusReachableViaWWAN) {
			...
		}
	}];
	
	
	[TSRestkitManager setNetworkLogLevel:RKLogLevelTrace];
	[TSRestkitManager setObjectMappingLogLevel:RKLogLevelTrace];
```

## Notes

TSUser subspec is highly experimental and messy right now. It also has some client-specific behaviour in it. Use at your own risk!!!
