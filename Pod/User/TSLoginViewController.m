//
//  TSLoginViewController.m
//  Pods
//
//  Created by Mark McFarlane on 24/06/2015.
//
//

#import "TSLoginViewController.h"
#import <TSUser.h>
#import <TSForgotPasswordViewController.h>
#import <UIAlertView+Blocks.h>

@interface TSLoginViewController ()

@end

@implementation TSLoginViewController

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	[self setupViewProperties];
	
	[self updateLoginButton];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userLoggedIn:) name:TSUserDidLoginNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginFailed:) name:TSUserDidFailLoginNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldTextDidChange) name:UITextFieldTextDidChangeNotification object:nil];
}

- (void)setupViewProperties
{
	[self.emailTextField setKeyboardType:UIKeyboardTypeEmailAddress];
	[self.passwordTextField setSecureTextEntry:YES];
	
	[self.emailTextField setDelegate:self];
	[self.passwordTextField setDelegate:self];

}

- (IBAction)loginButtonTapped:(UIButton *)sender
{
	[self loginRequest];
}

- (IBAction)forgotPasswordButtonTapped:(id)sender
{
	// Override this! Or create a forgot VC?
	
	UIViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"forgot_password"];
	if (vc) {
		TSForgotPasswordViewController *fpvc;
		
		if ([vc isKindOfClass:[UINavigationController class]]) {
			fpvc = [(UINavigationController *)vc viewControllers][0];
		} else if ([vc isKindOfClass:[TSForgotPasswordViewController class]]) {
			fpvc = (TSForgotPasswordViewController *)vc;
		}
		
		[fpvc setInitialEmailAddress:self.emailTextField.text];
		
		[self presentViewController:vc animated:YES completion:nil];
	} else {
		#warning What do we do in this sitution? Just throw an exception?
	}
}

- (IBAction)createAccountButtonTapped:(id)sender
{
	UIViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"create_account"];
	[self presentViewController:vc animated:YES completion:nil];
}

- (void)loginRequest
{
	[[TSUser sharedTSUser] loginWithEmail:self.emailTextField.text password:self.passwordTextField.text];
	
	[self animateToActiveNetworkState];
}

- (void)userLoggedIn:(NSNotification *)note
{
	[self dismissViewControllerAnimated:YES completion:^{ }];
}

- (void)loginFailed:(NSNotification *)note
{
	[self handleNoNetwork:note.object];
	
	[self revertToInactiveNetworkState];
}

- (void)handleNoNetwork:(NSString *)message
{
	[[[UIAlertView alloc] initWithTitle:@"Login error" message:message cancelButtonItem:[RIButtonItem itemWithLabel:@"OK" action:nil] otherButtonItems:[RIButtonItem itemWithLabel:@"Retry" action:^{
		[self loginButtonTapped:self.loginButton];
	}], nil] show];
}

- (void)animateToActiveNetworkState
{
	[self.spinner startAnimating];
	
	[UIView animateWithDuration:0.3 animations:^{
		[self.loginButton setAlpha:0];
//		[self.cancelButton setAlpha:0];
//		[self.karipasswordButtonContainerView setAlpha:0];
		[self.forgotPasswordButton setAlpha:0];
		[self.spinner setAlpha:1];
	}];
}

- (void)revertToInactiveNetworkState
{
	[self.loginButton setAlpha:1];
//	[self.cancelButton setAlpha:1];
//	[self.karipasswordButtonContainerView setAlpha:1];
	[self.spinner setAlpha:0];
	[self.spinner stopAnimating];
}

- (void)updateLoginButton
{
	BOOL enable = [self emailIsValid] && [self passwordIsValid];
	
	[self.loginButton setEnabled:enable];
}

#pragma mark -
#pragma Validation methods

-(BOOL)emailIsValid
{
	BOOL stricterFilter = NO; // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
	NSString *stricterFilterString = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
	NSString *laxString = @".+@.+\\.[A-Za-z]{2}[A-Za-z]*";
	NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
	NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
	return [emailTest evaluateWithObject:self.emailTextField.text];
}

- (BOOL)passwordIsValid
{
	return self.passwordTextField.text.length > 4;
}

#pragma mark -
#pragma UITextFieldDelegateMethods

- (void)textFieldTextDidChange
{
	[self updateLoginButton];
}

@end
