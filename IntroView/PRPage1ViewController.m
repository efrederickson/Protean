#import "PRPage1ViewController.h"

@interface PRPage1ViewController () {
    UILabel *mainLabel;
    UILabel *subLabel;
    UILabel *subLabel2;
    UIImageView *imgView;
}
@end

@implementation PRPage1ViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.view.backgroundColor = UIColor.clearColor;
        
        mainLabel = [[UILabel alloc] init];
        mainLabel.text = @"Protean";
        mainLabel.textColor = [UIColor whiteColor];
        mainLabel.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:70];
        mainLabel.frame = CGRectMake(0, 10, [UIScreen mainScreen].bounds.size.width, 100);
        mainLabel.textAlignment = NSTextAlignmentCenter;
        mainLabel.alpha = 0;
        [self.view addSubview:mainLabel];
        
        subLabel = [[UILabel alloc] init];
        subLabel.text = @"Your status bar, your way.";
        subLabel.textColor = [UIColor whiteColor];
        subLabel.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:25];
        subLabel.frame = CGRectMake(0, 55, [UIScreen mainScreen].bounds.size.width, 100);
        subLabel.textAlignment = NSTextAlignmentCenter;
        subLabel.alpha = 0;
        [self.view addSubview:subLabel];

        subLabel2 = [[UILabel alloc] init];
        subLabel2.text = @"The best way to personalize the status bar, for what you need.";
        subLabel2.textColor = [UIColor whiteColor];
        subLabel2.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:25];
        subLabel2.frame = CGRectMake(20, 130, [UIScreen mainScreen].bounds.size.width - 40, 100);
        subLabel2.textAlignment = NSTextAlignmentCenter;
        subLabel2.alpha = 0;
        subLabel2.lineBreakMode = NSLineBreakByWordWrapping;
        subLabel2.numberOfLines = 0;
        [self.view addSubview:subLabel2];
    
        imgView = [[UIImageView alloc] init];
        imgView.alpha = 0;
        // 320 = pre-6 device width
        imgView.frame = UIScreen.mainScreen.bounds;
        //CGRectMake(([UIScreen mainScreen].bounds.size.width-350)/2, UIScreen.mainScreen.bounds.size.height - 500, 350, 500);
        imgView.image = [UIImage imageWithContentsOfFile:@"/Library/Protean/iphone~large.png"];
        [self.view addSubview:imgView];
    }
    return self;
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [UIView animateWithDuration:1.4 animations:^{
        mainLabel.alpha = 1;
        subLabel.alpha = 1;
    }completion:^(BOOL finished) {
    [UIView animateWithDuration:1.1 animations:^{
        subLabel2.alpha = 1;
    }completion:^(BOOL finished) {
    [UIView animateWithDuration:1.4 animations:^{
        imgView.alpha = 1;
    } completion:^(BOOL finished) {
    }];
    }];
    }];
    
}
@end
