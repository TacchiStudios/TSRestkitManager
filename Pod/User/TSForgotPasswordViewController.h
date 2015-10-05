//
//  TSForgotPasswordViewController.h
//  Pods
//
//  Created by Mark McFarlane on 24/06/2015.
//
//

#import <UIKit/UIKit.h>

@interface TSForgotPasswordViewController : UIViewController

@property (nonatomic, copy) NSString *initialEmailAddress;

- (NSDictionary *)forgotPasswordParams; // Override this in subclasses to provide your own structure for the forgot password POST request

@end
