//
//  TSLoginViewController.h
//  Pods
//
//  Created by Mark McFarlane on 24/06/2015.
//
//

#import <UIKit/UIKit.h>

@interface TSLoginViewController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

@property (weak, nonatomic) IBOutlet UIButton *forgotPasswordButton;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;


- (void)animateToActiveNetworkState; // The user has tapped login, so we need to show some kind of spinner or something. Override this for custom behaviour.
- (void)revertToInactiveNetworkState; // The login failed or completed, so revert the UI to the standard login state.

- (BOOL)passwordIsValid; // Defaults to minimum 4 chars. Override to provide custom password validation

@end
