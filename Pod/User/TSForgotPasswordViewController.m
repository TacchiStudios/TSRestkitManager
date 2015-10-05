//
//  TSForgotPasswordViewController.m
//  Pods
//
//  Created by Mark McFarlane on 24/06/2015.
//
//

#import "TSForgotPasswordViewController.h"
#import <TSUser.h>

@interface TSForgotPasswordViewController ()

@property (strong, nonatomic) IBOutlet UITextField *emailTextField;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (strong, nonatomic) IBOutlet UIButton *sendButton;

@end

@implementation TSForgotPasswordViewController

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismiss)];
	[self.navigationItem setLeftBarButtonItem:button];
	
	[self.emailTextField setText:self.initialEmailAddress];
	[self updateSendButton];
	
	[self.spinner setHidesWhenStopped:YES];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didStartForgotPassword) name:TSUserDidStartForgotPasswordNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFinishForgotPassword) name:TSUserDidFinishForgotPasswordNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFailForgotPassword) name:TSUserDidFailForgotPasswordNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateSendButton) name:UITextFieldTextDidChangeNotification object:nil];
}

- (void)updateSendButton
{
	[self.sendButton setEnabled:[self allFieldsAreValid]];
}

- (BOOL)allFieldsAreValid
{
	return [self emailIsValid];
}

-(BOOL)emailIsValid
{
	BOOL stricterFilter = NO; // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
	NSString *stricterFilterString = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
	NSString *laxString = @".+@.+\\.[A-Za-z]{2}[A-Za-z]*";
	NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
	NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
	return [emailTest evaluateWithObject:self.emailTextField.text];
}

- (IBAction)forgotPasswordButtonTapped:(id)sender
{
	[[TSUser sharedTSUser] forgotPasswordForUserParams:[self forgotPasswordParams]];
}

- (NSDictionary *)forgotPasswordParams
{
	NSString *dummyName1 = @"Dummy";
	NSString *dummyName2 = @"Man";
	
	NSDictionary *params = @{@"user" : @{@"email" : self.emailTextField.text, @"name1" : dummyName1, @"name2" : dummyName2}};
	
	return params;
}

- (void)dismiss
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didStartForgotPassword
{
	[self animateToActiveNetworkState];
}

- (void)didFinishForgotPassword
{
	[self revertToInactiveNetworkState];
	
	#warning Nice success message
	
	[self dismiss];
}

- (void)didFailForgotPassword
{
	[self revertToInactiveNetworkState];
	
	#warning Nice fail message
}

- (void)animateToActiveNetworkState
{
	[self.spinner startAnimating];

	[UIView animateWithDuration:0.3 animations:^{
		[self.sendButton setAlpha:0];
		[self.spinner setAlpha:1];
	}];
}

- (void)revertToInactiveNetworkState
{
	[self.sendButton setAlpha:1];
	
	[self.spinner setAlpha:0];
	[self.spinner stopAnimating];
}

@end
