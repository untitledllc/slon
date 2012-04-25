#import <UIKit/UIKit.h>

@class RootViewController;

@interface BakerAppDelegate : NSObject <UIApplicationDelegate> {
	UIWindow *window;
	RootViewController *rootViewController;
}

@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, strong) RootViewController *rootViewController;

@end