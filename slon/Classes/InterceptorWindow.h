#import <Foundation/Foundation.h>
#import	"RootViewController.h"

@interface InterceptorWindow : UIWindow {
    UIView *target;
	RootViewController *eventsDelegate;
	
    BOOL isScrolling;
}
 
#pragma mark - Init
- (id)initWithTarget:(UIView *)targetView eventsDelegate:(UIViewController *)delegateController frame:(CGRect)aRect;

#pragma mark - Events management
- (void)forwardTap:(UITouch *)touch;

@end
