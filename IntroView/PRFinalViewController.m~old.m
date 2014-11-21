#import "PRFinalViewController.h"

@interface SpringBoard : UIApplication
-(void) PR_HideIntro;
@end

@interface PRFinalViewController () {
    UIImageView *closeButton;
    UILabel *label;
}
@end

@implementation PRFinalViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.view.backgroundColor = [UIColor colorWithRed:79/255.0f green:176/255.0f blue:136/255.0f alpha:1.0f];

        closeButton = [[UIImageView alloc] init];
        closeButton.image = [UIImage imageWithContentsOfFile:@"/Library/Protean/BowTie~large.png"];
        //closeButton.frame = CGRectMake(20, ([UIScreen mainScreen].bounds.size.height-150)/2, [UIScreen mainScreen].bounds.size.width - 40, 150);
        closeButton.frame = CGRectMake(110, ([UIScreen mainScreen].bounds.size.height-130)/2, [UIScreen mainScreen].bounds.size.width - (110*2), 40);
        closeButton.userInteractionEnabled = YES;
        [self.view addSubview:closeButton];

        label = [[UILabel alloc] init];
        label.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:40];
        label.text = @"Protean";
        label.textColor = [UIColor whiteColor];
        label.frame = CGRectMake(100, ([UIScreen mainScreen].bounds.size.height-100)/2, [UIScreen mainScreen].bounds.size.width - (80*2), 150);
        [self.view addSubview:label];

        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)];
        [closeButton addGestureRecognizer:tapGestureRecognizer];

        // Auto-close after 3 seconds
        [self performSelector:@selector(closeMe) withObject:nil afterDelay:3];
    }
    return self;
}

-(void) closeMe
{
    SpringBoard *sb = (SpringBoard*)[UIApplication sharedApplication];
    [sb PR_HideIntro];
}

- (void) handleTapFrom: (UITapGestureRecognizer *)recognizer
{
    CABasicAnimation *transformAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
    transformAnimation.toValue=[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.4, 1.4, 1)];
    //transformAnimation.fromValue=[NSValue valueWithCATransform3D:CATransform3DMakeScale(0.8, 0.8, 1)];
    transformAnimation.duration = 0.4;
    transformAnimation.autoreverses = YES;
    transformAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

    [closeButton.layer addAnimation:transformAnimation forKey:@"kBounce"];
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}
@end
