#import "PRPage2ViewController.h"

@interface PRPage2ViewController () {
    UILabel *mainLabel;
    UILabel *subLabel;
    UILabel *subLabel1;
    UIImageView *imgView;
}
@end

@implementation PRPage2ViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        mainLabel = [[UILabel alloc] init];
        mainLabel.text = @"Add Notifications";
        mainLabel.textColor = [UIColor whiteColor];
        mainLabel.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:40];
        mainLabel.frame = CGRectMake(0, 10, [UIScreen mainScreen].bounds.size.width, 100);
        mainLabel.textAlignment = NSTextAlignmentCenter;
        mainLabel.alpha = 0;
        [self.view addSubview:mainLabel];
        
        subLabel1 = [[UILabel alloc] init];
        subLabel1.text = @"to your status bar";
        subLabel1.textColor = [UIColor whiteColor];
        subLabel1.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:25];
        subLabel1.frame = CGRectMake(0, 40, [UIScreen mainScreen].bounds.size.width, 100);
        subLabel1.textAlignment = NSTextAlignmentCenter;
        subLabel1.alpha = 0;
        [self.view addSubview:subLabel1];
        
        subLabel = [[UILabel alloc] init];
        subLabel.text = @"As well as Flipswitches,\nBluetooth devices,\nand more.";
        subLabel.textColor = [UIColor whiteColor];
        subLabel.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:25];
        subLabel.frame = CGRectMake(0, 110, [UIScreen mainScreen].bounds.size.width, 100);
        subLabel.textAlignment = NSTextAlignmentCenter;
        subLabel.alpha = 0;
        subLabel.lineBreakMode = NSLineBreakByWordWrapping;
        subLabel.numberOfLines = 3;
        [self.view addSubview:subLabel];
        
        imgView = [[UIImageView alloc] init];
        imgView.alpha = 0;
        imgView.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width-(229/2))/2, 210, (229/2), 20);
        imgView.image = [UIImage imageNamed:@"StatusBar2"];
        [self.view addSubview:imgView];
    }
    return self;
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [UIView animateWithDuration:1.4 animations:^{
        mainLabel.alpha = 1;
        subLabel1.alpha = 1;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:1.1 animations:^{
            subLabel.alpha = 1;
        }completion:^(BOOL finished) {
            [UIView animateWithDuration:1.2 animations:^{
                imgView.alpha = 1;
            }completion:^(BOOL finished) {
            }];
        }];
    }];
    
}

@end
