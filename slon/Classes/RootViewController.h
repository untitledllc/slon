#import <UIKit/UIKit.h>
#import "IndexViewController.h"

@interface RootViewController : UIViewController < UIWebViewDelegate, UIScrollViewDelegate > {
	
	CGRect screenBounds;
	
	NSString *documentsBookPath;
    NSString *bundleBookPath;
    
    NSString *availableOrientation;
    NSString *renderingType;
	
	NSMutableArray *pages;
    NSMutableArray *toLoad;
    NSMutableArray *pageDetails;
    UIImage *backgroundImageLandscape;
    UIImage *backgroundImagePortrait;
    
	NSString *pageNameFromURL;
	NSString *anchorFromURL;
	
    int tapNumber;
    int stackedScrollingAnimations;
    
	BOOL currentPageFirstLoading;
	BOOL currentPageIsDelayingLoading;
    BOOL currentPageHasChanged;
    
    UIScrollView *scrollView;
	UIWebView *prevPage;
	UIWebView *currPage;
	UIWebView *nextPage;
    
	int totalPages;
    int lastPageNumber;
	int currentPageNumber;
	
    int pageWidth;
	int pageHeight;
    int currentPageHeight;
    
    IndexViewController *indexViewController;
}

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic) UIWebView *currPage;
@property int currentPageNumber;
@property BOOL tocState;
@property BOOL videoState;
@property int vPage;
@property int resultY;
@property (nonatomic, strong) UIWebView *preview;
@property (nonatomic, strong) UIWebView *full;
@property (nonatomic, retain) NSString *ipadType;

- (void)setupWebView:(UIWebView *)webView;
- (void)setPageSize:(NSString *)orientation;
- (void)resetScrollView;
- (void)initBook:(NSString *)path;
- (BOOL)changePage:(int)page;
- (void)gotoPage;
- (void)addPageLoading:(int)slot;
- (void)handlePageLoading;
- (void)loadSlot:(int)slot withPage:(int)page;
- (BOOL)loadWebView:(UIWebView *)webview withPage:(int)page;
- (CGRect)frameForPage:(int)page;
- (void)resetScrollView;
- (void)webView:(UIWebView *)webView hidden:(BOOL)status animating:(BOOL)animating;
- (void)userDidTap:(UITouch *)touch;
- (void)getPageHeight;
- (void)toggleToc;
- (NSString *)getCurrentInterfaceOrientation;

@end