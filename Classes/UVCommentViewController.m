//
//  UVCommentViewController.m
//  UserVoice
//
//  Created by Austin Taylor on 11/15/12.
//  Copyright (c) 2012 UserVoice Inc. All rights reserved.
//

#import "UVCommentViewController.h"
#import "UVSuggestion.h"
#import "UVTextView.h"
#import "UVComment.h"
#import "UVSuggestionDetailsViewController.h"
#import "UVBabayaga.h"
#import "UVTextWithFieldsView.h"
#import "UVSession.h"

@implementation UVCommentViewController {
    UVTextWithFieldsView *_fieldsView;
    UITextField *_emailField;
    UITextField *_nameField;
}

- (id)initWithSuggestion:(UVSuggestion *)theSuggestion {
    if ((self = [super init])) {
        _suggestion = theSuggestion;
    }
    return self;
}

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)commentButtonTapped {
    if (_fieldsView.textView.text.length == 0) {
        [self dismiss];
    } else {
        [self disableSubmitButton];
        [self showActivityIndicator];
        // TODO if needed sign the user in
        [UVComment createWithSuggestion:_suggestion text:_fieldsView.textView.text delegate:self];
    }
}

- (void)didCreateComment:(UVComment *)comment {
    [self hideActivityIndicator];
    [UVBabayaga track:COMMENT_IDEA id:_suggestion.suggestionId];
    _suggestion.commentsCount += 1;
    UINavigationController *navController = (UINavigationController *)self.presentingViewController;
    UVSuggestionDetailsViewController *previous = (UVSuggestionDetailsViewController *)[navController.viewControllers lastObject];
    [previous reloadComments];
    [self dismiss];
}

- (void)loadView {
    [super loadView];
    self.navigationItem.title = NSLocalizedStringFromTable(@"Add a comment", @"UserVoice", nil);
    UIView *view = [UIView new];
    view.frame = [self contentFrame];
    view.backgroundColor = [UIColor whiteColor];

    _fieldsView = [UVTextWithFieldsView new];
    _fieldsView.textView.placeholder = NSLocalizedStringFromTable(@"Write a comment...", @"UserVoice", nil);
    if ([UVSession currentSession].user) {
        _emailField = [_fieldsView addFieldWithLabel:NSLocalizedStringFromTable(@"Email", @"UserVoice", nil)];
        _emailField.placeholder = NSLocalizedStringFromTable(@"(required)", @"UserVoice", nil);
        _emailField.keyboardType = UIKeyboardTypeEmailAddress;
        _emailField.autocorrectionType = UITextAutocorrectionTypeNo;
        _emailField.autocapitalizationType = UITextAutocapitalizationTypeNone;

        _nameField = [_fieldsView addFieldWithLabel:NSLocalizedStringFromTable(@"Name", @"UserVoice", nil)];
        _nameField.placeholder = NSLocalizedStringFromTable(@"“Anonymous”", @"UserVoice", nil);
    }

    [self configureView:view
               subviews:NSDictionaryOfVariableBindings(_fieldsView)
            constraints:@[@"|[_fieldsView]|", @"V:|[_fieldsView]|"]];

    self.view = view;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Cancel", @"UserVoice", nil)
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(dismiss)];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Comment", @"UserVoice", nil)
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(commentButtonTapped)];
    [_fieldsView.textView becomeFirstResponder];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [_fieldsView performSelector:@selector(updateLayout) withObject:nil afterDelay:0];
}

- (UIScrollView *)scrollView {
    return _fieldsView;
}

@end
