#import "PRFinalViewController.h"

@interface SpringBoard : UIApplication
-(void) PR_HideIntro;
@end

@interface PRFinalViewController () {
    UILabel *mainLabel;
    UILabel *subLabel;
    UIButton *closeButton;
}
@end

@implementation PRFinalViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.view.backgroundColor = [UIColor whiteColor];

        mainLabel = [[UILabel alloc] init];
        mainLabel.text = @"Welcome to";
        mainLabel.textColor = [UIColor darkGrayColor];
        mainLabel.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:40];
        mainLabel.frame = CGRectMake(0, 10, [UIScreen mainScreen].bounds.size.width, 100);
        mainLabel.textAlignment = NSTextAlignmentCenter;
        mainLabel.alpha = 1;
        [self.view addSubview:mainLabel];
        
        subLabel = [[UILabel alloc] init];
        subLabel.text = @"Your status bar, your way.\n\nAdd Applications, Flipswitches, Bluetooth devices, and more to your status bar.\n\nCustomize organization, visibility, and layout.\n\nCustomize the battery percentage and carrier!\nAnd much more.";
        subLabel.textColor = [UIColor darkGrayColor];
        subLabel.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:20];
        subLabel.frame = CGRectMake(0, 55, [UIScreen mainScreen].bounds.size.width, 400);
        subLabel.textAlignment = NSTextAlignmentCenter;
        subLabel.alpha = 0;
        subLabel.lineBreakMode = NSLineBreakByWordWrapping;
        subLabel.numberOfLines = 12;
        [self.view addSubview:subLabel];
        
        closeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [closeButton setTitle:@"Get started!" forState:UIControlStateNormal];
        closeButton.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width-200)/2, 450, 200, 20);
        [closeButton addTarget:self action:@selector(closeMe) forControlEvents:UIControlEventTouchUpInside];
        closeButton.alpha = 0;
        closeButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:25];
        [self.view addSubview:closeButton];
    }
    return self;
}

-(void) closeMe
{
    SpringBoard *sb = (SpringBoard*)[UIApplication sharedApplication];
    [sb PR_HideIntro];
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [UIView animateWithDuration:0.4 animations:^{
        mainLabel.alpha = .5;
    } completion:^(BOOL finished) {
        mainLabel.text = @"Welcome to.";
        [UIView animateWithDuration:0.4 animations:^{
            mainLabel.alpha = 1;

            [UIView animateWithDuration:.4 delay:.5 options:UIViewAnimationOptionCurveLinear animations: ^{
                mainLabel.alpha = .5;
            } completion:^(BOOL finished) {
                mainLabel.text = @"Welcome to..";
                [UIView animateWithDuration:0.4 animations:^{
                    mainLabel.alpha = 1;

                    [UIView animateWithDuration:.4 delay:.5 options:UIViewAnimationOptionCurveLinear animations: ^{
                        mainLabel.alpha = .5;
                    } completion:^(BOOL finished) {
                        mainLabel.text = @"Welcome to...";
                        [UIView animateWithDuration:0.4 animations:^{
                            mainLabel.alpha = 1;

                            [UIView animateWithDuration:.4 delay:.5 options:UIViewAnimationOptionCurveLinear animations: ^{
                                mainLabel.alpha = .5;
                            } completion:^(BOOL finished) {
                                mainLabel.text = @"Protean";
                                mainLabel.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:75];
                                [UIView animateWithDuration:0.4 animations:^{
                                    mainLabel.alpha = 1;
                                }];
                            }];
                        }];
                    }];
                }];
            }];
        }];
    }];

    [UIView animateWithDuration:1 delay:3.5 options:UIViewAnimationOptionCurveLinear animations: ^{
        subLabel.alpha = 1;
    } completion:nil];
     
    [UIView animateWithDuration:1 delay:4 options:UIViewAnimationOptionCurveLinear animations: ^{
            closeButton.alpha = 1;
    } completion:nil];
    
}
@end
