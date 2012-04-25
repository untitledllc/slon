#import "BakerAppDelegate.h"
#import "RootViewController.h"
#import "InterceptorWindow.h"

@implementation BakerAppDelegate

@synthesize window;
@synthesize rootViewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //Для рекламного блока РЖД по требованию заказчика
    sleep(3);
    
	application.applicationSupportsShakeToEdit = NO;
	self.rootViewController = [[RootViewController alloc] init];
	self.window = [[InterceptorWindow alloc] initWithTarget:self.rootViewController.scrollView eventsDelegate:self.rootViewController frame:[[UIScreen mainScreen]bounds]];
    window.backgroundColor = [UIColor whiteColor];
	[window addSubview:rootViewController.view];
    [window makeKeyAndVisible];

	return YES;
}

@end
