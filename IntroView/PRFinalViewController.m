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
        mainLabel = [[UILabel alloc] init];
        mainLabel.text = @"Protean";
        mainLabel.textColor = [UIColor darkGrayColor];
        mainLabel.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:75];
        mainLabel.frame = CGRectMake(0, 10, [UIScreen mainScreen].bounds.size.width, 100);
        mainLabel.textAlignment = NSTextAlignmentCenter;
        mainLabel.alpha = 0;
        [self.view addSubview:mainLabel];
        
        subLabel = [[UILabel alloc] init];
        subLabel.text = @"You are now ready to use Protean";
        subLabel.textColor = [UIColor darkGrayColor];
        subLabel.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:20];
        subLabel.frame = CGRectMake(0, 55, [UIScreen mainScreen].bounds.size.width, 100);
        subLabel.textAlignment = NSTextAlignmentCenter;
        subLabel.alpha = 0;
        [self.view addSubview:subLabel];
        
        closeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [closeButton setTitle:@"Get started!" forState:UIControlStateNormal];
        closeButton.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width-200)/2, 150, 200, 20);
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
    
    [UIView animateWithDuration:1 animations:^{
        mainLabel.alpha = 1;
        subLabel.alpha = 1;
    } completion:nil];
     
    [UIView animateWithDuration:1 delay:0.5 options:UIViewAnimationOptionCurveLinear animations: ^{
            closeButton.alpha = 1;
    } completion:nil];
    
}
@end
