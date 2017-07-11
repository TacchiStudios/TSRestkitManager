//
//  TSUserConfirmSharedLoginViewController.h
//  Pods
//
//  Created by Mark McFarlane on 10/07/2017.
//
//

#import <UIKit/UIKit.h>

@interface TSUserConfirmSharedLoginViewController : UIViewController

@property (copy) void (^confirmBlock)(void);
@property (nonatomic, copy) NSString *loggedInEmail;

@end
