#import "InterceptorWindow.h"
#import "RootViewController.h"

@implementation InterceptorWindow

- (id)initWithTarget:(UIView *)targetView eventsDelegate:(UIViewController *)delegateController frame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        target = targetView;
        eventsDelegate = (RootViewController *)delegateController;
    }
    return self;
}

- (void)sendEvent:(UIEvent *)event {
	BOOL shouldCallParent = YES;
	
	if (event.type == UIEventTypeTouches) {
		
        NSSet *touches = [event allTouches];		
		if (touches.count == 1) {
			
            UITouch *touch = touches.anyObject;
			
			if (touch.phase == UITouchPhaseBegan) {
				isScrolling = NO;
			} else if (touch.phase == UITouchPhaseMoved) {
				isScrolling = YES;
			}
        
			if (touch.tapCount > 1) {
                if (touch.phase == UITouchPhaseEnded && !isScrolling) {
                    [self performSelector:@selector(forwardTap:) withObject:touch];
				}
				shouldCallParent = NO;
			} else if ([touch.view isDescendantOfView:target] == YES) {
                if (touch.phase == UITouchPhaseEnded) {
					[self performSelector:@selector(forwardTap:) withObject:touch];
				}
			} 
		}
	}

	if (shouldCallParent) {
		[super sendEvent:event];
	}
}

- (void)forwardTap:(UITouch *)touch {
	[eventsDelegate userDidTap:touch];
}

@end