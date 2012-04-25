#import "IndexViewController.h"

@implementation IndexViewController

- (id)initWithBookBundlePath:(NSString *)path documentsBookPath:(NSString *)docpath fileName:(NSString *)name webViewDelegate:(UIViewController<UIWebViewDelegate> *)delegate {
    bookBundlePath = path;
    documentsBookPath = docpath;
    fileName = name;
    webViewDelegate = delegate;
    disabled = NO;
    indexHeight = 0;
    
    [self setPageSizeForOrientation:UIInterfaceOrientationPortrait];
    
    return [self initWithNibName:nil bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    // Initialization to 1x1px is required to get sizeThatFits to work
    UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 1024, 1, 1)];
    webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    webView.delegate = self;
    
    webView.backgroundColor = [UIColor clearColor];
    [webView setOpaque:NO];

    [[[webView subviews] lastObject] setShowsVerticalScrollIndicator:NO];
    [[[webView subviews] lastObject] setShowsHorizontalScrollIndicator:NO];
    
    self.view = webView;
    
    [self loadContent];
}

- (void)setBounceForWebView:(UIWebView *)webView bounces:(BOOL)bounces {
    for (id subview in webView.subviews)
        if ([[subview class] isSubclassOfClass: [UIScrollView class]])
            ((UIScrollView *)subview).bounces = bounces;
}

- (void)setPageSizeForOrientation:(UIInterfaceOrientation)orientation {
	CGRect screenBounds = [[UIScreen mainScreen] bounds];

	if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
		pageWidth = screenBounds.size.height;
		pageHeight = screenBounds.size.width;
    } else {
        pageWidth = screenBounds.size.width;
		pageHeight = screenBounds.size.height;
	}
}

- (BOOL)isIndexViewHidden {
    return [UIApplication sharedApplication].statusBarHidden;
}

- (BOOL)isDisabled {
    return disabled;
}

- (void)setIndexViewHidden:(BOOL)hidden withAnimation:(BOOL)animation {
    CGRect frame;
    if (hidden) {
        frame = CGRectMake(0, pageHeight + pageY, pageWidth, indexHeight);
    } else {
        frame = CGRectMake(0, pageHeight + pageY - indexHeight, pageWidth, indexHeight);
    }
    
    if (animation) {
        [UIView beginAnimations:@"slideIndexView" context:nil]; {
            [UIView setAnimationDuration:0.3];
            
            self.view.frame = frame;
        }
        [UIView commitAnimations];
    } else {
        self.view.frame = frame;
    }
    
}

- (void)fadeOut {
    [UIView beginAnimations:@"fadeOutIndexView" context:nil]; {
        [UIView setAnimationDuration:0.0];
        
        self.view.alpha = 0.0;
    }
    [UIView commitAnimations];
}

- (void)fadeIn {
    [UIView beginAnimations:@"fadeInIndexView" context:nil]; {
        [UIView setAnimationDuration:0.2];
        
        self.view.alpha = 1.0;
    }
    [UIView commitAnimations];
}

- (void)willRotate {
    [self fadeOut];
}

- (void)rotateFromOrientation:(UIInterfaceOrientation)fromInterfaceOrientation toOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    BOOL hidden = [self isIndexViewHidden]; // cache hidden status before setting page size
    
    [self setPageSizeForOrientation:toInterfaceOrientation];
    [self setIndexViewHidden:hidden withAnimation:NO];
    [self fadeIn];
}
- (void)loadContent{
    [self loadContentFromBundle:true];
}

- (void)loadContentFromBundle:(BOOL)fromBundle{
    NSString* path;
    if(fromBundle){
        path = [bookBundlePath stringByAppendingPathComponent:fileName];
    } else {
        path = [documentsBookPath stringByAppendingPathComponent:fileName];
    }

    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        disabled = NO;
		[(UIWebView *)self.view loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];
	} else {
        disabled = YES;
    }
}

-(void)webViewDidFinishLoad:(UIWebView *)webView {
    indexHeight = 200;        
    webView.delegate = webViewDelegate;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end
