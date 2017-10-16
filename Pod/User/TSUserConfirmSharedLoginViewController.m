//
//  TSUserConfirmSharedLoginViewController.m
//  Pods
//
//  Created by Mark McFarlane on 10/07/2017.
//
//

#import "TSUserConfirmSharedLoginViewController.h"
#import "TSUser.h"
#import <TSRestkitManager.h>
#import "UIAlertController+Window.h"

#define LS(s) NSLocalizedString(s, nil)

#define TSLocalizedStringTokenExchangeFailed LS(@"Login Error")

@interface TSUserConfirmSharedLoginViewController ()

@property (strong, nonatomic) IBOutlet UILabel *messageLabel;
@property (strong, nonatomic) IBOutlet UIButton *continueButton;
@property (strong, nonatomic) IBOutlet UIButton *logoutButton;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end


@implementation TSUserConfirmSharedLoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	[self.messageLabel setText:[NSString stringWithFormat:NSLocalizedString(@"tsuser.confirmlogin.message", nil), self.loggedInEmail]];
	[self.continueButton setTitle:[NSString stringWithFormat:NSLocalizedString(@"tsuser.confirmlogin.continue", nil), self.loggedInEmail] forState:UIControlStateNormal];
	[self.logoutButton setTitle:NSLocalizedString(@"tsuser.confirmlogin.logout", nil) forState:UIControlStateNormal];

	[self.continueButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
	[self.logoutButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismiss) name:@"TSUserDidLogoutAllApps" object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismiss) name:TSUserDidLoginNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showTokenExchangeErrorAlert:) name:TSUserDidFailExchangingTokenNotification object:nil];
}

- (void)dealloc
{
	// TODO: Remove once we only support iOS 9+
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)logoutButtonTapped:(UIButton *)sender
{
	[[TSUser sharedTSUser] logoutFrom:self];
}

- (IBAction)continueButtonTapped:(UIButton *)sender
{
	[self.activityIndicator setAlpha:0];
	
	[UIView animateWithDuration:0.3 animations:^{
		[self.continueButton setAlpha:0];
		[self.logoutButton setAlpha:0];
		[self.activityIndicator setAlpha:1];
	} completion:^(BOOL finished) {
		self.confirmBlock();
	}];
}

- (void)showTokenExchangeErrorAlert:(NSNotification *)notification
{
	[UIView animateWithDuration:0.3 animations:^{
		[self.continueButton setAlpha:1];
		[self.logoutButton setAlpha:1];
		[self.activityIndicator setAlpha:0];
	}];

	
	AFRKHTTPRequestOperation *operation = notification.object;
	
	NSString *message = nil;
	
	// For now, always show so we can debug via TF.
	//		#ifdef DEBUG
	message = operation.error.localizedDescription;
	//		#endif
	
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:TSLocalizedStringTokenExchangeFailed message:message preferredStyle:UIAlertControllerStyleAlert];
	[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Dismiss", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
	}]];
	[alert show];
}

- (void)dismiss
{
	[self dismissViewControllerAnimated:YES completion:^{}];
}

@end
