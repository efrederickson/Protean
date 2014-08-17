#import "PRViewController.h"
#import "PRPage1ViewController.h"
#import "PRPage2ViewController.h"
#import "PRFinalViewController.h"

@interface PRViewController () {
    NSInteger _index;
}

@end

@implementation PRViewController
- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    
    self.pageController.dataSource = self;
    [[self.pageController view] setFrame:[[self view] bounds]];
    
    UIViewController *initialViewController = [self viewControllerAtIndex:0];
    
    NSArray *viewControllers = [NSArray arrayWithObject:initialViewController];
    
    [self.pageController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
    [self addChildViewController:self.pageController];
    [[self view] addSubview:[self.pageController view]];
    [self.pageController didMoveToParentViewController:self];
    _index = 0;
    
    // after creating the UIPageViewController
    for (UIView *subview in self.pageController.view.subviews) {
        if ([subview isKindOfClass:[UIPageControl class]]) {
            UIPageControl *pageControl = (UIPageControl *)subview;
            pageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
            pageControl.currentPageIndicatorTintColor = [UIColor blackColor];
            pageControl.backgroundColor = [UIColor whiteColor];
        }
    }
}

- (UIViewController *)viewControllerAtIndex:(NSUInteger)index {
    if (index == 0)
    {
        PRPage1ViewController *ret = [[PRPage1ViewController alloc] init];
        ret.index = index;
        return ret;
    }
    else if (index == 1)
    {
        PRPage2ViewController *ret = [[PRPage2ViewController alloc] init];
        ret.index = index;
        return ret;
    }
    else if (index == 2)
    {
        PRFinalViewController *ret = [[PRFinalViewController alloc] init];
        ret.index = index;
        return ret;
    }
    return nil;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    
    NSUInteger index = [(PRPage1ViewController*)viewController index];
    
    if (index == 0) {
        return nil;
    }
    
    // Decrease the index by 1 to return
    index--;
    _index = index;
    return [self viewControllerAtIndex:index];
    
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    
    NSUInteger index = [(PRPage1ViewController *)viewController index];
    
    index++;
    _index = index;
    return [self viewControllerAtIndex:index];
    
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController {
    // The number of items reflected in the page indicator.
    return 3;
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController {
    // The selected item reflected in the page indicator.
    return _index;
}

@end
