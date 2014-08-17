#import "PRPage1ViewController.h"

@interface PRPage1ViewController () {
    UILabel *mainLabel;
    UILabel *subLabel;
    UIImageView *imgView;
}
@end

@implementation PRPage1ViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.view.backgroundColor = [UIColor clearColor];
        
        mainLabel = [[UILabel alloc] init];
        mainLabel.text = @"Protean";
        mainLabel.textColor = [UIColor darkGrayColor];
        mainLabel.font = [UIFont fontWithName:@"Helvetica Neue" size:70];
        mainLabel.frame = CGRectMake(0, 10, [UIScreen mainScreen].bounds.size.width, 100);
        mainLabel.textAlignment = NSTextAlignmentCenter;
        mainLabel.alpha = 0;
        [self.view addSubview:mainLabel];
        
        subLabel = [[UILabel alloc] init];
        subLabel.text = @"Your status bar, your way.";
        subLabel.textColor = [UIColor darkGrayColor];
        subLabel.font = [UIFont fontWithName:@"Helvetica Neue" size:25];
        subLabel.frame = CGRectMake(0, 55, [UIScreen mainScreen].bounds.size.width, 100);
        subLabel.textAlignment = NSTextAlignmentCenter;
        subLabel.alpha = 0;
        [self.view addSubview:subLabel];
    
        imgView = [[UIImageView alloc] init];
        imgView.alpha = 0;
        imgView.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width-320)/2, 150, 320, 20);
        imgView.image = [UIImage imageNamed:@"StatusBar1"];
        [self.view addSubview:imgView];
    }
    return self;
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [UIView animateWithDuration:1.4 animations:^{
        mainLabel.alpha = 1;
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
