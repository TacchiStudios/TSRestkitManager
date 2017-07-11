//
//  TSUserConfirmSharedLoginViewController.m
//  Pods
//
//  Created by Mark McFarlane on 10/07/2017.
//
//

#import "TSUserConfirmSharedLoginViewController.h"
#import "TSUser.h"

@interface TSUserConfirmSharedLoginViewController ()

@property (strong, nonatomic) IBOutlet UILabel *messageLabel;
@property (strong, nonatomic) IBOutlet UIButton *continueButton;
@property (strong, nonatomic) IBOutlet UIButton *logoutButton;

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
	[self dismissViewControllerAnimated:YES completion:^{
		self.confirmBlock();
	}];
}

- (void)dismiss
{
	[self dismissViewControllerAnimated:YES completion:^{}];
}

@end
