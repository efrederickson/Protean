#import <UIKit/UIKit.h>

@interface PRViewController : UIViewController <UIPageViewControllerDataSource>
@property (strong, nonatomic) UIPageViewController *pageController;
@end
