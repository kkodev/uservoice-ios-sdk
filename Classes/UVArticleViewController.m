//
//  UVArticleViewController.m
//  UserVoice
//
//  Created by Austin Taylor on 5/8/12.
//  Copyright (c) 2012 UserVoice Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "UVArticleViewController.h"
#import "UVSession.h"
#import "UVNewTicketViewController.h"
#import "UVStyleSheet.h"
#import "UVBabayaga.h"
#import "UVDeflection.h"

@implementation UVArticleViewController

@synthesize article;
@synthesize webView;
@synthesize helpfulPrompt;
@synthesize returnMessage;
@synthesize instantAnswers;

- (id)initWithArticle:(UVArticle *)theArticle helpfulPrompt:(NSString *)theHelpfulPrompt returnMessage:(NSString *)theReturnMessage{
    if (self = [super init]) {
        self.article = theArticle;
        self.helpfulPrompt = theHelpfulPrompt;
        self.returnMessage = theReturnMessage;
        [UVBabayaga track:VIEW_ARTICLE id:article.articleId];
    }
    return self;
}

- (void)loadView {
    [super loadView];
    self.navigationItem.title = NSLocalizedStringFromTable(@"Knowledge Base", @"UserVoice", nil);
    self.view = [[[UIView alloc] initWithFrame:[self contentFrame]] autorelease];

    if(article != nil){
        [self loadWebView];
    }
    else{
        [self showActivityIndicator];
    }
}

-(void)loadWebView{
    self.webView = [[[UIWebView alloc] initWithFrame:self.view.bounds] autorelease];
    NSString *html = [NSString stringWithFormat:@"<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"http://cdn.uservoice.com/stylesheets/vendor/typeset.css\"/></head><body class=\"typeset\" style=\"font-family: HelveticaNeue-Light; margin: 1em; font-size: 15px\"><h3>%@</h3><br/>%@</body></html>", article.question, article.answerHTML];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    if ([self.webView respondsToSelector:@selector(scrollView)]) {
        self.webView.backgroundColor = [UIColor whiteColor];
        for (UIView* shadowView in [[self.webView scrollView] subviews]) {
            if ([shadowView isKindOfClass:[UIImageView class]]) {
                [shadowView setHidden:YES];
            }
        }
    }
    [self.webView loadHTMLString:html baseURL:nil];
    self.webView.delegate = self;
    [self.view addSubview:webView];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (helpfulPrompt) {
        if (buttonIndex == 0) {
            [self.navigationController popViewControllerAnimated:YES];
        } else if (buttonIndex == 1) {
            [self dismissUserVoice];
        }
    } else {
        if (buttonIndex == 0) {
            [self presentModalViewController:[UVNewTicketViewController viewController]];
        }
    }
}

- (void)yesButtonTapped {
    [UVBabayaga track:VOTE_ARTICLE id:article.articleId];
    if (instantAnswers) {
        [UVDeflection trackDeflection:@"helpful" deflector:article];
    }
    if (helpfulPrompt) {
        // Do you still want to contact us?
        // Yes, go to my message
        UIActionSheet *actionSheet = [[[UIActionSheet alloc] initWithTitle:helpfulPrompt
                                                                  delegate:self
                                                         cancelButtonTitle:NSLocalizedStringFromTable(@"Cancel", @"UserVoice", nil)
                                                    destructiveButtonTitle:nil
                                                         otherButtonTitles:returnMessage, NSLocalizedStringFromTable(@"No, I'm done", @"UserVoice", nil), nil] autorelease];
        [actionSheet showInView:self.view];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)noButtonTapped {
    if (instantAnswers) {
        [UVDeflection trackDeflection:@"unhelpful" deflector:article];
    }
    if (helpfulPrompt) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        UIActionSheet *actionSheet = [[[UIActionSheet alloc] initWithTitle:NSLocalizedStringFromTable(@"Would you like to contact us?", @"UserVoice", nil)
                                                                  delegate:self
                                                         cancelButtonTitle:NSLocalizedStringFromTable(@"No", @"UserVoice", nil)
                                                    destructiveButtonTitle:nil
                                                         otherButtonTitles:NSLocalizedStringFromTable(@"Yes", @"UserVoice", nil), nil] autorelease];
        [actionSheet showInView:self.view];
    }
}

- (void)dealloc {
    self.article = nil;
    self.webView = nil;
    self.helpfulPrompt = nil;
    self.returnMessage = nil;
    [super dealloc];
}

#pragma mark - UIWebViewDelegate

// Open links in Safari

-(BOOL) webView:(UIWebView *)inWeb shouldStartLoadWithRequest:(NSURLRequest *)inRequest navigationType:(UIWebViewNavigationType)inType {
    if ( inType == UIWebViewNavigationTypeLinkClicked ) {
        
        NSString *urlString = inRequest.URL.absoluteString;
        
        // If this is a link to another article, push that article
        
        NSRegularExpression *regex = [NSRegularExpression
                                      regularExpressionWithPattern:@"https?://[a-z]+\\.uservoice\\.com/knowledgebase/articles/([0-9]+)-.+"
                                      options:0
                                      error:nil];
        
        NSTextCheckingResult *match   = [regex firstMatchInString:urlString
                                                   options:0
                                                     range:NSMakeRange(0, [urlString length])];
        
        if (match) {
            NSRange range = [match rangeAtIndex:1];
            NSInteger articleId = [[urlString substringWithRange:range] integerValue];

            UVArticleViewController* pushedArticleViewController = [[UVArticleViewController alloc] initWithArticle:nil
                                                                                                      helpfulPrompt:nil
                                                                                                      returnMessage:nil];
            
            [UVArticle getArticleWithId:articleId delegate:pushedArticleViewController];

            
            [self.navigationController pushViewController:pushedArticleViewController animated:YES];
        }

        // Else open in safari
        
        else{
            [[UIApplication sharedApplication] openURL:[inRequest URL]];
        }
        return NO;
    }
    
    return YES;
}

-(void) didRetrieveArticle:(UVArticle*) receivedArticle{
    if(self.article == nil){
        self.article = receivedArticle;
        [self hideActivityIndicator];
        [self loadWebView];
    }
}

@end
