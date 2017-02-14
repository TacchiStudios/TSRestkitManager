# TSRestkitManager

## About

A simple, quick, standardized way to get Restkit and MagicalRecord set up in your iOS project.

## Getting Started

Include the following line in your podfile (will get this on the core pods repo soon)
```ruby
pod 'TSRestkitManager', :git => 'https://github.com/TacchiStudios/TSRestkitManager.git', :tag => 'v0.2.0'
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

Now you can simply use `[RKObjectManager sharedManager]` as you usually would throughout your app!


## TSUser

The TSUser subspec is intended to be a drop-in solution for oAuth2 authentication in your app. It integrates with TSRestkitManager to reduce boilerplate code and decouple your view controllers from the login/logout flow.

_TSUser is __highly experimental, incomplete, and messy right now__. It also still has some client-specific behaviour in it. Use at your own risk!!!_

### Setup

To add TSUser to your project, add the following alongside the above line

```ruby
pod 'TSRestkitManager/User', :git => 'https://github.com/TacchiStudios/TSRestkitManager.git', :tag => 'v0.2.0'
```

First, you'll need some kind of storage for your auth credentials. It should conform to the `TSUserStorage` protocol. The repo includes the following basic storage types that you can use:

```Objective-C
TSUserDefaultsStorage *storage = [[TSUserDefaultsStorage alloc] init];
```
```
TSPrivateKeychainStorage *storage = [[TSPrivateKeychainStorage alloc] init];
```
```
TSSharedKeychainStorage *storage = [[TSSharedKeychainStorage alloc] init];
[storage setAccessGroup:@"ABCDEFGHIJ.com.yourcompany.yoursharedkeychain"];
```
```
TSSharedKeychainPerAppStorage *storage = [[TSSharedKeychainPerAppStorage alloc] init];
[storage setAccessGroup:@"ABCDEFGHIJ.com.yourcompany.yoursharedkeychain"];
```
Then set up TSUser and pass it your storage

```
TSUser *user = [TSUser sharedTSUser];
[user setStorage:storage];


[user setClientId:OAUTH_CLIENT_ID secret:OAUTH_CLIENT_SECRET];
[user setBaseURL:BASE_URL];
[user setLoginPath:@"oauth/token"];
[user setForgotPasswordPath:@"forgot_password"];
etc...
[user setupAuthHeader]; // You must call this after setting all above options, this will setup the oAuth header in RKObjectManager's HTTPClient for all future requests 
```

See TSUser.h for full setup options.

### Logging in

To login, call:
```
[[TSUser sharedTSUser] loginWithEmail:email password:password];
```
TSUser will send out a variety of NSNotifications based on the success or failure of its login request.

### Logging out

To logout, call:
```
[[TSUser sharedTSUser] logout];
```
TSUser will send out an NSNotifications to inform the rest of your app.

### Other actions

See TSUser.h for other methods, such as creating accounts, fotgot password requests etc.

## TODO

- More documentation for TSUser on creating accounts, anonymous sessions etc.
- A lof of tidying up of the code, and probably some refactoring!
- Finish off TSLoginViewController etc

