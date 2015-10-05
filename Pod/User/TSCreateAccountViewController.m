//
//  TSCreateAccountViewController.m
//  Pods
//
//  Created by Mark McFarlane on 24/06/2015.
//
//

#import "TSCreateAccountViewController.h"

@interface TSCreateAccountViewController ()

@property (strong, nonatomic) IBOutlet UITextField *emailTextField;
@property (strong, nonatomic) IBOutlet UIButton *sendButton;

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@end


@implementation TSCreateAccountViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismiss)];
	[self.navigationItem setLeftBarButtonItem:button];
	
	[self.spinner setHidesWhenStopped:YES];

}

- (void)dismiss
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
