#import <UIKit/UIKit.h>

@interface IndexViewController : UIViewController <UIWebViewDelegate> {
    NSString *bookBundlePath;
    NSString *documentsBookPath;
    NSString *fileName;
    UIViewController<UIWebViewDelegate> *webViewDelegate;
    
    int pageY;
    int pageWidth;
	int pageHeight;
    int indexHeight;
    BOOL disabled;
}

- (id)initWithBookBundlePath:(NSString *)path documentsBookPath:(NSString *)docpath fileName:(NSString *)name webViewDelegate:(UIViewController *)delegate;
- (void)loadContent;
- (void)loadContentFromBundle:(BOOL)fromBundle;
- (void)setBounceForWebView:(UIWebView *)webView bounces:(BOOL)bounces;
- (void)setPageSizeForOrientation:(UIInterfaceOrientation)orientation;
- (BOOL)isIndexViewHidden;
- (BOOL)isDisabled;
- (void)setIndexViewHidden:(BOOL)hidden withAnimation:(BOOL)animation;
- (void)willRotate;
- (void)rotateFromOrientation:(UIInterfaceOrientation)fromInterfaceOrientation toOrientation:(UIInterfaceOrientation)toInterfaceOrientation;
- (void)fadeOut;
- (void)fadeIn;

@end
