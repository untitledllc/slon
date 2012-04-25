#import "RootViewController.h"
#import "Utils.h"

#include <sys/sysctl.h>

#define INDEX_FILE_NAME @"index.html"
#define SCROLLVIEW_BGCOLOR colorWithRed:1 green:1 blue:1 alpha:1.0f

@implementation RootViewController

@synthesize scrollView;
@synthesize currPage;
@synthesize currentPageNumber;
@synthesize tocState;
@synthesize videoState;
@synthesize vPage;
@synthesize resultY;
@synthesize preview;
@synthesize full;
@synthesize ipadType;

#pragma mark - INIT
- (id)init {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        size_t size;
        sysctlbyname("hw.machine", NULL, &size, NULL, 0);
        char *model = malloc(size);
        sysctlbyname("hw.machine", model, &size, NULL, 0);
        ipadType = [NSString stringWithCString:model encoding:NSUTF8StringEncoding];
        free(model);
        if([ipadType isEqualToString:@"iPad1,1"] || [ipadType isEqualToString:@"iPad1,2"]){
            ipadType = @"iPad1";
        } else {
            ipadType = @"iPad2orHigher";
        }
        
        screenBounds = [[UIScreen mainScreen] bounds];
        
        NSString *privateDocsPath = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"Private Documents"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:privateDocsPath]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:privateDocsPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        if (![[NSFileManager defaultManager] fileExistsAtPath:cachePath]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        bundleBookPath        = [[NSBundle mainBundle] pathForResource:@"book" ofType:nil];
        documentsBookPath     = [privateDocsPath stringByAppendingPathComponent:@"book"];
        
        pages = [NSMutableArray array];
        toLoad = [NSMutableArray array];
        pageDetails = [NSMutableArray array];
        
        pageNameFromURL = nil;
        anchorFromURL = nil;
        
        tapNumber = 0;
        stackedScrollingAnimations = 0;
        
        currentPageFirstLoading = YES;
        currentPageIsDelayingLoading = YES;
        currentPageHasChanged = NO;
        
        [self setPageSize:[self getCurrentInterfaceOrientation]];
        
        self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, pageWidth, pageHeight)];
        scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        scrollView.showsHorizontalScrollIndicator = NO;
        scrollView.showsVerticalScrollIndicator = NO;
        scrollView.delaysContentTouches = NO;
        scrollView.pagingEnabled = YES;
        scrollView.delegate = self;
        
        tocState = NO;
        videoState = YES;
        vPage = 1;
        
        if([ipadType isEqualToString:@"iPad2orHigher"]){
            preview = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, 1024, 1024)];
            [preview loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"book/preview-%d", 0] ofType:@"html"]isDirectory:NO]]];
            preview.hidden = NO;
        }

        /*[full loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"book/full-%d", 0] ofType:@"html"]isDirectory:NO]]];*/
        
        [self.view addSubview:scrollView];
        
        indexViewController = [[IndexViewController alloc] initWithBookBundlePath:bundleBookPath documentsBookPath:documentsBookPath fileName:INDEX_FILE_NAME webViewDelegate:self];
        
        for (UIView *subview in indexViewController.view.subviews) {
            if ([subview isKindOfClass:[UIScrollView class]]) {
                ((UIScrollView *)subview).bounces = NO;
            }
        }
        
        [self.view addSubview:indexViewController.view];

        if ([[NSFileManager defaultManager] fileExistsAtPath:documentsBookPath]) {
            [self initBook:documentsBookPath];
        } else {
            if ([[NSFileManager defaultManager] fileExistsAtPath:bundleBookPath]) {
                [self initBook:bundleBookPath];
            }
        }
	}
	return self;
}

- (void)setupWebView:(UIWebView *)webView {
    webView.delegate = self;
    webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [[[webView subviews] lastObject] setShowsVerticalScrollIndicator:NO];
    [[[webView subviews] lastObject] setShowsHorizontalScrollIndicator:NO];
	
    webView.mediaPlaybackRequiresUserAction = NO;
    webView.scalesPageToFit = NO;
    
    for (UIView *subview in webView.subviews) {
        if ([subview isKindOfClass:[UIScrollView class]]) {
            ((UIScrollView *)subview).bounces = NO;
        }
    }
}

- (void)setPageSize:(NSString *)orientation {
	if ([orientation isEqualToString:@"landscape"]) {
		pageWidth = screenBounds.size.height;
		pageHeight = screenBounds.size.width;
	} else {
        pageWidth = screenBounds.size.width;
        pageHeight = screenBounds.size.height;
    }
}

- (void)resetScrollView {
    scrollView.contentSize = CGSizeMake(pageWidth * totalPages, pageHeight);
    
    if (prevPage && [prevPage.superview isEqual:scrollView]) {
        prevPage.frame = [self frameForPage:currentPageNumber - 1];
        [scrollView bringSubviewToFront:prevPage];
    }
    
    if (nextPage && [nextPage.superview isEqual:scrollView]) {
        nextPage.frame = [self frameForPage:currentPageNumber + 1];
        [scrollView bringSubviewToFront:nextPage];
    }
    
    if (currPage) {
        currPage.frame = [self frameForPage:currentPageNumber];
    }
    
    [scrollView bringSubviewToFront:currPage];
    [scrollView scrollRectToVisible:[self frameForPage:currentPageNumber] animated:NO];
}

- (void)initBook:(NSString *)path {
    availableOrientation = @"both";
    renderingType = @"three-cards";
    scrollView.backgroundColor = [Utils colorWithHexString:@"#ffffff"];
    backgroundImageLandscape = [UIImage imageWithContentsOfFile:[path stringByAppendingPathComponent:@"images/background-landscape.png"]];
    backgroundImagePortrait = [UIImage imageWithContentsOfFile:[path stringByAppendingPathComponent:@"images/background-portrait.png"]];
    NSArray *bookPages = [[NSArray alloc] initWithObjects:@"article-0.html",@"article-1.html",@"article-2.html",@"article-3.html",@"article-4.html",@"article-5.html",@"article-6.html",@"article-7.html",@"article-8.html",@"article-9.html",@"article-10.html",@"article-11.html",@"article-12.html",@"article-13.html",@"article-14.html",@"article-15.html",@"article-16.html", nil];
    NSEnumerator *pagesEnumerator = [bookPages objectEnumerator];
    id page;

    while ((page = [pagesEnumerator nextObject])) {
        NSString *pageFile = nil;
        if ([page isKindOfClass:[NSString class]]) {
            pageFile = [path stringByAppendingPathComponent:page];
        } else if ([page isKindOfClass:[NSDictionary class]]) {
            pageFile = [path stringByAppendingPathComponent:[page objectForKey:@"url"]];
        }
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:pageFile]) {
            [pages addObject:pageFile];
        }
    }

	totalPages = [pages count];
	
	if (totalPages > 0) {
        currentPageNumber = 1;
        
        currentPageIsDelayingLoading = YES;
        [toLoad removeAllObjects];
        
        [self resetScrollView];
        [self addPageLoading:0];
        
        if (currentPageNumber != totalPages) {
            [self addPageLoading:+1];
        }
        
        if (currentPageNumber != 1) {
            [self addPageLoading:-1];
        }
        
        [self handlePageLoading];
        
        [indexViewController loadContentFromBundle:[path isEqualToString:bundleBookPath]];
	}
}

#pragma mark - LOADING
- (BOOL)changePage:(int)page {
    BOOL pageChanged = NO;

    if (page < 1)
    {
		currentPageNumber = 1;
	}
    else if (page > totalPages)
    {
		currentPageNumber = totalPages;
	} 
    else if (page != currentPageNumber)
    {
        scrollView.scrollEnabled = NO;
        stackedScrollingAnimations++;
        
        lastPageNumber = currentPageNumber;
		currentPageNumber = page;
        
        tapNumber = tapNumber + (lastPageNumber - currentPageNumber);

        [scrollView scrollRectToVisible:[self frameForPage:currentPageNumber] animated:YES];
        
        [self gotoPage];
        
        pageChanged = YES;
	}
    
	return pageChanged;
}

- (void)gotoPage {
    NSString *path = [NSString stringWithString:[pages objectAtIndex:currentPageNumber - 1]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path] && tapNumber != 0) {
        
        tocState = YES;
        [self performSelector:@selector(toggleToc) withObject:nil];
        
        int direction = 1;
        if (tapNumber < 0) {
            direction = -direction;
            tapNumber = -tapNumber;
        }
        
        if (tapNumber > 2) {
            tapNumber = 0;
            
            // ****** Moved away for more than 2 pages: RELOAD ALL pages
            [toLoad removeAllObjects];                
            [currPage removeFromSuperview];
            [nextPage removeFromSuperview];
            [prevPage removeFromSuperview];

            [self addPageLoading:0];
            if (currentPageNumber < totalPages)
                [self addPageLoading:+1];
            if (currentPageNumber > 1)
                [self addPageLoading:-1];
            
        } else {
            
            int tmpSlot = 0;
            if (tapNumber == 2) {
                // ****** Moved away for 2 pages: RELOAD CURRENT page
                if (direction < 0) {
                    // ****** Move LEFT <<<
                    [prevPage removeFromSuperview];
                    UIWebView *tmpView = prevPage;
                    prevPage = nextPage;
                    nextPage = tmpView;
                } else {
                    // ****** Move RIGHT >>>
                    [nextPage removeFromSuperview];
                    UIWebView *tmpView = nextPage; 
                    nextPage = prevPage;
                    prevPage = tmpView;
                }
                
                // Adjust pages slot in the stack to reflect the webviews pointer change
                for (int i = 0; i < [toLoad count]; i++) {
                    tmpSlot =  -1 * [[[toLoad objectAtIndex:i] valueForKey:@"slot"] intValue];
                    [[toLoad objectAtIndex:i] setObject:[NSNumber numberWithInt:tmpSlot] forKey:@"slot"];
                }
                
                [currPage removeFromSuperview];
                [self addPageLoading:0];
                
            } else if (tapNumber == 1) {
                
                if (direction < 0) {
                    // ****** Move LEFT <<<
                    [prevPage removeFromSuperview];
                    UIWebView *tmpView = prevPage;
                    prevPage = currPage;
                    currPage = nextPage;
                    nextPage = tmpView;
                    
                } else {
                    // ****** Move RIGHT >>>
                    [nextPage removeFromSuperview];
                    UIWebView *tmpView = nextPage;
                    nextPage = currPage;
                    currPage = prevPage;
                    prevPage = tmpView;                        
                }
                
                // Adjust pages slot in the stack to reflect the webviews pointer change
                for (int i = 0; i < [toLoad count]; i++) {
                    tmpSlot = [[[toLoad objectAtIndex:i] valueForKey:@"slot"] intValue];
                    if (direction < 0) {
                        if (tmpSlot == +1) {
                            tmpSlot = 0;
                        } else if (tmpSlot == 0) {
                            tmpSlot = -1;
                        } else if (tmpSlot == -1) {
                            tmpSlot = +1;
                        }
                    } else {
                        if (tmpSlot == -1) {
                            tmpSlot = 0;
                        } else if (tmpSlot == 0) {
                            tmpSlot = +1;
                        } else if (tmpSlot == +1) {
                            tmpSlot = -1;
                        }
                    }
                    [[toLoad objectAtIndex:i] setObject:[NSNumber numberWithInt:tmpSlot] forKey:@"slot"];
                }
            }
            
            [self getPageHeight];
            
            tapNumber = 0;
            if (direction < 0) {
                
                // REMOVE OTHER NEXT page from toLoad stack
                for (int i = 0; i < [toLoad count]; i++) {
                    if ([[[toLoad objectAtIndex:i] valueForKey:@"slot"] intValue] == +1) {
                        [toLoad removeObjectAtIndex:i];
                    }   
                }
                
                // PRELOAD NEXT page
                if (currentPageNumber < totalPages) {
                    [self addPageLoading:+1];
                }
                
            } else {
                
                // REMOVE OTHER PREV page from toLoad stack
                for (int i = 0; i < [toLoad count]; i++) {
                    if ([[[toLoad objectAtIndex:i] valueForKey:@"slot"] intValue] == -1) {
                        [toLoad removeObjectAtIndex:i];
                    }   
                }
                
                // PRELOAD PREV page
                if (currentPageNumber > 1) {
                    [self addPageLoading:-1];
                }
            }
        }
        
        [self handlePageLoading];
    }

    full = [[UIWebView alloc] init];
    [self setupWebView:full];
    full.frame = [self frameForPage:currentPageNumber];
    full.hidden = YES;
    ((UIScrollView *)[[full subviews] objectAtIndex:0]).pagingEnabled = YES;
    [full loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"book/full-%d", currentPageNumber - 1] ofType:@"html"]isDirectory:NO]]];

    currPage = full;
    currentPageHasChanged = YES;

    //Отправляем в разные браузеры JS уведомления о перелистывании страницы
    [prevPage stringByEvaluatingJavaScriptFromString:@"pageClosed();"];
    [nextPage stringByEvaluatingJavaScriptFromString:@"pageClosed();"];
    /*[currPage stringByEvaluatingJavaScriptFromString:@"pageOpened();"];

    //для РЖД видео показываем только 1 раз
    if(3 == currentPageNumber && YES == videoState){
        [currPage stringByEvaluatingJavaScriptFromString:@"startVideo();"];
        videoState = NO;
    }*/
    
    if([ipadType isEqualToString:@"iPad2orHigher"]){
        [preview loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"book/preview-%d", currentPageNumber - 1] ofType:@"html"]isDirectory:NO]]];
    }
}

- (void)addPageLoading:(int)slot {    
    NSArray *objs = [NSArray arrayWithObjects:[NSNumber numberWithInt:slot], [NSNumber numberWithInt:currentPageNumber + slot], nil];
    NSArray *keys = [NSArray arrayWithObjects:@"slot", @"page", nil];
    
    if (slot == 0) {
        [toLoad insertObject:[NSMutableDictionary dictionaryWithObjects:objs forKeys:keys] atIndex:0];
    } else {
        [toLoad addObject:[NSMutableDictionary dictionaryWithObjects:objs forKeys:keys]];
    }
}

- (void)handlePageLoading {
    if ([toLoad count] != 0) {
        int slot = [[[toLoad objectAtIndex:0] valueForKey:@"slot"] intValue];
        int page = [[[toLoad objectAtIndex:0] valueForKey:@"page"] intValue];
        
        [toLoad removeObjectAtIndex:0];
        
        [self loadSlot:slot withPage:page];
    }
}

- (void)loadSlot:(int)slot withPage:(int)page {
    UIWebView *webView = [[UIWebView alloc] init];
    [self setupWebView:webView];
    
    webView.frame = [self frameForPage:page];
    webView.hidden = YES;

	if (slot == 0) {
        
        if (currPage) {
            currPage.delegate = nil;
            if ([currPage isLoading]) {
                [currPage stopLoading];
            }
        }
        currPage = webView;
        currentPageHasChanged = YES;
        
	} else if (slot == +1) {
        
        if (nextPage) {
            nextPage.delegate = nil;
            if ([nextPage isLoading]) {
                [nextPage stopLoading];
            }
        }
        nextPage = webView;
        
    } else if (slot == -1) {
        
        if (prevPage) {
            prevPage.delegate = nil;
            if ([prevPage isLoading]) {
                [prevPage stopLoading];
            }
        }
        prevPage = webView;
    }
    
    
    ((UIScrollView *)[[webView subviews] objectAtIndex:0]).pagingEnabled = YES;
    
    [scrollView addSubview:webView];
	[self loadWebView:webView withPage:page];
}

- (BOOL)loadWebView:(UIWebView*)webView withPage:(int)page {
	
	NSString *path = [NSString stringWithString:[pages objectAtIndex:page - 1]];
    
	if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
		[webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];
		return YES;
	}
	return NO;
}

#pragma mark - SCROLLVIEW
- (CGRect)frameForPage:(int)page {
    return CGRectMake(pageWidth * (page - 1), 0, pageWidth, pageHeight);
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scroll {
    int page = (int)(scroll.contentOffset.x / pageWidth) + 1;
    
    if (currentPageNumber != page) {
        lastPageNumber = currentPageNumber;
        currentPageNumber = page;
        tapNumber = tapNumber + (lastPageNumber - currentPageNumber);
		[self gotoPage];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scroll {
    stackedScrollingAnimations--;
    if (stackedScrollingAnimations == 0) {
		scroll.scrollEnabled = YES;
	}
}

#pragma mark - WEBVIEW
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    NSURL *url = [request URL];
    
    if ([webView isEqual:prevPage])
    {
        return YES;
    } 
    else if ([webView isEqual:nextPage])
    {
        return YES;
    } 
    else if (currentPageIsDelayingLoading)
    {		
		currentPageIsDelayingLoading = NO;
		return YES;
	}
    else
    {
		[indexViewController setIndexViewHidden:YES withAnimation:NO];
        
		if (url)
        {
            if([[url lastPathComponent] isEqualToString:INDEX_FILE_NAME])
            {
                return YES;
            }
            else
            {
                if ([[url scheme] isEqualToString:@"file"])
                {
                    anchorFromURL  = [url fragment];
                    NSString *file = [[url relativePath] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                    
                    int page = [pages indexOfObject:file];
                    if (page == NSNotFound)
                    {
                        return YES;
                    }
                    
                    page = page + 1;
                    if (![self changePage:page] && ![webView isEqual:indexViewController.view])
                    {
                        if (anchorFromURL == nil) {
                            return YES;
                        }
                    }
                }
                else
                {
                    NSString *params = [url query];
                    if (params != nil)
                    {                        
                        NSRegularExpression *referrerRegex = [NSRegularExpression regularExpressionWithPattern:@"referrer=Baker" options:NSRegularExpressionCaseInsensitive error:NULL];
                        NSUInteger matches = [referrerRegex numberOfMatchesInString:params options:0 range:NSMakeRange(0, [params length])];
                        
                        if (matches > 0) {
                            [[UIApplication sharedApplication] openURL:url];
                            return NO;
                        }
                    }
                    
                    return YES;
                }
            }
        }
		return NO;
	}
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"WebKitCacheModelPreferenceKey"];
    if (webView.hidden == YES)
    {
        if ([webView isEqual:currPage]) {
            currentPageHasChanged = NO;
            [self getPageHeight];
        }
        
        [webView removeFromSuperview];
        webView.hidden = NO;
        
        [self webView:webView hidden:NO animating:NO];
        [self handlePageLoading];
    }
}

- (void)webView:(UIWebView *)webView hidden:(BOOL)status animating:(BOOL)animating {
    [scrollView addSubview:webView];
}

#pragma mark - GESTURES
- (void)userDidTap:(UITouch *)touch {
    if ((touch.tapCount%2) == 0) {
        //блокируем оглавление на ржд
        if(3 != currentPageNumber && 7 != currentPageNumber && 11 != currentPageNumber && 15 != currentPageNumber){
            [self performSelector:@selector(toggleToc) withObject:nil];
        }
    }
}

#pragma mark - PAGE SCROLLING
- (void)getPageHeight {
	for (UIView *subview in currPage.subviews) {
		if ([subview isKindOfClass:[UIScrollView class]]) {
			CGSize size = ((UIScrollView *)subview).contentSize;
			currentPageHeight = size.height;
		}
	}
}

#pragma mark - CHAPTER LIST
- (void)toggleToc {
	if(tocState){
        [indexViewController setIndexViewHidden:YES withAnimation:NO];
        tocState = NO;
    } else {
        [indexViewController setIndexViewHidden:NO withAnimation:NO];
        tocState = YES;
    }
}

#pragma mark - ORIENTATION
- (NSString *)getCurrentInterfaceOrientation {
    if ([availableOrientation isEqualToString:@"portrait"] || [availableOrientation isEqualToString:@"landscape"])
    {
        return availableOrientation;
    } 
    else {
        if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
            return @"landscape";
        } else {
            return @"portrait";
        }
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if(![ipadType isEqualToString:@"iPad2orHigher"]){
        [toLoad removeAllObjects];
        [nextPage removeFromSuperview];
        [prevPage removeFromSuperview];
    } else {
        [self.view addSubview:preview];
    }

    NSString *currPageOffset = [currPage stringByEvaluatingJavaScriptFromString:@"window.scrollY;"];
    int posY = [currPageOffset intValue];
    
    if (@"landscape" == [self getCurrentInterfaceOrientation]) {
        vPage = posY / 768;
    } else {
        vPage = posY / 1024;
    }
    if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft || toInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {    
        resultY = vPage * 768;
    } else {
        resultY = vPage * 1024;
    }
    vPage++;

    if (@"landscape" == [self getCurrentInterfaceOrientation]) {
        [currPage stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"rotateWithParam(%d, 'portrait');", vPage]];
        if([ipadType isEqualToString:@"iPad2orHigher"]){
            [preview stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"ProtateWithParam(%d, 'portrait');", vPage]];
            [prevPage stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"rotateWithParam(%d, 'portrait');", vPage]];
            [nextPage stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"rotateWithParam(%d, 'portrait');", vPage]];
        }
    } else {
        [currPage stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"rotateWithParam(%d, 'landscape');", vPage]];
        if([ipadType isEqualToString:@"iPad2orHigher"]){
            [preview stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"ProtateWithParam(%d, 'landscape');", vPage]];
            [prevPage stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"rotateWithParam(%d, 'landscape');", vPage]];
            [nextPage stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"rotateWithParam(%d, 'landscape');", vPage]];
        }
    }

    [currPage stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.scrollTo(0,%d);", resultY]];

    [indexViewController willRotate];

    if([ipadType isEqualToString:@"iPad2orHigher"]){
        [self.view bringSubviewToFront:preview];
        //preview.hidden = NO;
        scrollView.hidden = YES;
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [indexViewController rotateFromOrientation:fromInterfaceOrientation toOrientation:self.interfaceOrientation];
    
    [self setPageSize:[self getCurrentInterfaceOrientation]];
    [self getPageHeight];
	[self resetScrollView];
    
    [self.view bringSubviewToFront:scrollView];
    [self.view bringSubviewToFront:indexViewController.view];
    if([ipadType isEqualToString:@"iPad2orHigher"]){
        scrollView.hidden = NO;
        //preview.hidden = YES;
        //[preview removeFromSuperview];
    } else {
        [self addPageLoading:+1];
        [self addPageLoading:-1];
    }
}

#pragma mark - MEMORY
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
	[super viewDidUnload];
    
    preview.delegate = nil;
    currPage.delegate = nil;
	nextPage.delegate = nil;
	prevPage.delegate = nil;
}

@end