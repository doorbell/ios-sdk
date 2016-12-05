#import "DoorbellDialog.h"
#import <QuartzCore/QuartzCore.h>

NSString * const DoorbellSite = @"http://doorbell.io";

@interface DoorbellDialog ()

@property (strong, nonatomic) UITextView *bodyView;
@property (strong, nonatomic) UITextField *emailField;
@property (strong, nonatomic) UIButton *cancelButton;
@property (strong, nonatomic) UIButton *sendButton;
@property (strong, nonatomic) UIView *poweredBy;
@property (strong, nonatomic) UILabel *bodyPlaceHolderLabel;
@property (strong, nonatomic) UILabel *sendingLabel;
@property (strong, nonatomic) UIViewController *parentViewController;

@property UIDeviceOrientation lastDeviceOrientation;

@end

@implementation DoorbellDialog

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _showEmail = YES;
        _showPoweredBy = YES;
        _sending = NO;
        // Initialization code
        self.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.3];
        self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin;
        CGRect boxFrame;
        boxFrame.size = CGSizeMake(300, 255);
        boxFrame = [self calculateNewBoxFrame:boxFrame];
        _boxView = [[UIView alloc] initWithFrame:boxFrame];
        _boxView.backgroundColor = [UIColor whiteColor];
        _boxView.layer.masksToBounds = NO;
        _boxView.layer.cornerRadius = 4.0f;
        //_boxView.layer.borderColor = [UIColor blackColor].CGColor;
        //_boxView.layer.borderWidth = 1.0f;
        _boxView.layer.shadowColor = [UIColor blackColor].CGColor;
        _boxView.layer.shadowRadius = 10.0f;
        _boxView.layer.shadowOffset = CGSizeMake(0, 1);
        _boxView.layer.shadowOpacity = 0.2f;
        _boxView.clipsToBounds = YES;

        [self addSubview:_boxView];

    }
    return self;
}

- (id)initWithViewController:(UIViewController *)vc
{
    CGRect frame = vc.view.bounds;
    self = [self initWithFrame:frame];
    if (self) {
        self.parentViewController = vc;

        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter]
         addObserver:self selector:@selector(orientationChanged:)
         name:UIDeviceOrientationDidChangeNotification
         object:[UIDevice currentDevice]];
    }
    return self;
}

- (void)dealloc
{
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void) recalculateFrame
{
    CGRect frame = self.parentViewController.view.bounds;

    CGRect boxFrame;
    boxFrame.size = CGSizeMake(300, 255);
    boxFrame.origin.x = (frame.size.width/2) - boxFrame.size.width/2;
    boxFrame.origin.y = (frame.size.height - boxFrame.size.height) / 2;

    _boxView.frame = boxFrame;
}

- (void) orientationChanged:(NSNotification *)note
{
    // Hide the keyboard, so when the dialog is centered is looks OK
    UIDevice *device = [note object];
    if ([device orientation] != UIDeviceOrientationFaceUp &&
        [device orientation] != UIDeviceOrientationFaceDown &&
        [device orientation] != UIDeviceOrientationUnknown &&
        [device orientation] != self.lastDeviceOrientation )
    {
        [[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];
        self.lastDeviceOrientation = [device orientation];
        [self recalculateFrame];
    }
}

- (NSString*)bodyText
{
    return [_bodyView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (void)setEmail:(NSString *)email
{
    if (email.length > 0) {
        self.emailField.text = email;
    }
}

- (NSString*)email
{
    return [self.emailField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (void)goToDoorbell:(id)sender
{
    NSURL *doorbellURL = [NSURL URLWithString:DoorbellSite];
    [[UIApplication sharedApplication] openURL:doorbellURL];
}

- (void)send:(id)sender
{
    if (self.bodyText.length == 0) {
        [self highlightMessageEmpty];
        return;
    }

    if ([_delegate respondsToSelector:@selector(dialogDidSend:)]) {
        [_delegate dialogDidSend:self];
    }
}

- (void)cancel:(id)sender
{
    if ([_delegate respondsToSelector:@selector(dialogDidCancel:)]) {
        [_delegate dialogDidCancel:self];
    }
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)highlightMessageEmpty
{
    _bodyPlaceHolderLabel.text = NSLocalizedString(@"Please add some feedback", nil);
    _bodyPlaceHolderLabel.textColor = [UIColor redColor];
    [_bodyView becomeFirstResponder];
}

- (void)highlightEmailEmpty
{
    _emailField.layer.borderColor = [UIColor redColor].CGColor;
    _emailField.placeholder = NSLocalizedString(@"Please add an email", nil);
    [_emailField becomeFirstResponder];
}

- (void)highlightEmailInvalid
{
    _emailField.layer.borderColor = [UIColor redColor].CGColor;
    [_emailField becomeFirstResponder];
}

- (void)setShowEmail:(BOOL)showEmail
{
    _showEmail = showEmail;
    _emailField.hidden = !showEmail;
    [self layoutSubviews];
}

- (void)setShowPoweredBy:(BOOL)showPoweredBy
{
    _showPoweredBy = showPoweredBy;
    _poweredBy.hidden = !showPoweredBy;
    [self layoutSubviews];
}

-(void)setVerticleOffset:(CGFloat)verticleOffset
{
    _verticleOffset = verticleOffset;

    _boxView.frame = [self calculateNewBoxFrame:_boxView.frame];
}

- (UILabel*)sendingLabel
{
    if (!_sendingLabel) {
        _sendingLabel = [[UILabel alloc] initWithFrame:_bodyView.frame];
        _sendingLabel.font = [UIFont boldSystemFontOfSize:18.0f];
        _sendingLabel.textAlignment = NSTextAlignmentCenter;
        _sendingLabel.textColor =  self.primaryColor;
        _sendingLabel.text = NSLocalizedString(@"Sending ...", nil);
    }

    return _sendingLabel;
}

- (void)setSending:(BOOL)sending
{
    _sending = sending;
    _bodyView.hidden = sending;
    if (_showEmail) {
        _emailField.hidden = sending;
    }
    if (_showPoweredBy) {
        _poweredBy.hidden = sending;
    }
    _cancelButton.hidden = sending;
    _sendButton.hidden = sending;

    if (sending) {
        [_boxView addSubview:self.sendingLabel];
    }
    else {
        [self.sendingLabel removeFromSuperview];
    }
}
/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
 }
 */

-(CGRect)calculateNewBoxFrame:(CGRect)boxFrame
{
    boxFrame.origin.x = (self.frame.size.width/2) - boxFrame.size.width/2;
    boxFrame.origin.y = ((self.frame.size.height - boxFrame.size.height) / 2) + _verticleOffset;

    return boxFrame;
}

- (void)layoutSubviews
{
    float offsetY = _bodyView.frame.origin.y + _bodyView.frame.size.height + 10.0f;
    if (_showEmail) {
        _emailField.frame = CGRectMake(10.0f, offsetY, 280.0f, 30.0f);
        offsetY += 40;
    }

    if (_showPoweredBy) {
        _poweredBy.frame = CGRectMake(10.0f, offsetY, 280.0f, 14.0f);
        offsetY += 24;
    }

    _cancelButton.frame = CGRectMake(0.0f, offsetY, 150.0f, 44.0f);
    _sendButton.frame = CGRectMake(150.0f, offsetY, 150.0f, 44.0f);

    CGRect frame = _boxView.frame;
    frame.size.height = offsetY + 44.0f;
    _boxView.frame = frame;

    [super layoutSubviews];
}

- (void)createBoxSubviews
{
    UIColor *brandColor = self.primaryColor
    ? self.primaryColor
    : [UIColor colorWithRed:91/255.0f green:192/255.0f blue:222/255.0f alpha:1.0f];

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20.0f, 10.0f, 200.0f, 20.0f)];
    titleLabel.text = NSLocalizedString(@"Feedback", nil);
    titleLabel.font = self.titleFont
    ? self.titleFont
    : [UIFont boldSystemFontOfSize:18.0f];

    titleLabel.textAlignment = NSTextAlignmentLeft;
    titleLabel.textColor = brandColor;

    [_boxView addSubview:titleLabel];

    CALayer *line = [CALayer layer];
    line.frame = CGRectMake(0, 35.0f, 300.0f, 1.0f);
    line.backgroundColor = brandColor.CGColor;
    [_boxView.layer addSublayer:line];

    _bodyView = [[UITextView alloc] initWithFrame:CGRectMake(10.0f, 45.0f, 280.0f, 100)];
    _bodyView.delegate = self;
    _bodyView.textColor = [UIColor darkTextColor];
    _bodyView.font = self.textFont
    ? self.textFont
    : [UIFont systemFontOfSize:16.0f];

    _bodyView.dataDetectorTypes = UIDataDetectorTypeNone;
    _bodyView.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.2].CGColor;
    _bodyView.layer.borderWidth  = 1.0 / [UIScreen mainScreen].scale;
    _bodyView.keyboardAppearance = UIKeyboardAppearanceAlert;
    _bodyView.layer.cornerRadius = 4;

    UIBarButtonItem *bodyDoneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil)
                                                                       style:UIBarButtonItemStyleDone target:_bodyView action:@selector(resignFirstResponder)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    toolbar.items = [NSArray arrayWithObjects:flexibleSpace, bodyDoneButton, nil];
    _bodyView.inputAccessoryView = toolbar;


    [_boxView addSubview:_bodyView];

    _bodyPlaceHolderLabel = [[UILabel alloc] initWithFrame:CGRectMake(8.0f, 10.0f, 260.0f, 20.0f)];
    _bodyPlaceHolderLabel.text = NSLocalizedString(@"What's on your mind?", nil);
    _bodyPlaceHolderLabel.font = _bodyView.font;
    _bodyPlaceHolderLabel.textColor = [UIColor lightGrayColor];
    _bodyPlaceHolderLabel.userInteractionEnabled = NO;
    [_bodyView addSubview:_bodyPlaceHolderLabel];

    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 20)];


    _emailField = [[UITextField alloc] initWithFrame:CGRectMake(10.0f, 155.0f, 280.0f, 30.0f)];
    _emailField.delegate = self;

    NSAttributedString * emailAstring = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Your email address", nil)
                                                                        attributes:@{NSFontAttributeName : self.textFont}];

    _emailField.attributedPlaceholder = emailAstring;
    _emailField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _emailField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _emailField.borderStyle = UITextBorderStyleLine;
    _emailField.keyboardType = UIKeyboardTypeEmailAddress;
    _emailField.keyboardAppearance = UIKeyboardAppearanceAlert;
    _emailField.returnKeyType = UIReturnKeySend;
    _emailField.layer.masksToBounds = YES;
    _emailField.borderStyle = UITextBorderStyleNone;
    _emailField.leftView = paddingView;
    _emailField.leftViewMode = UITextFieldViewModeAlways;
    _emailField.layer.borderColor =[UIColor colorWithWhite:0 alpha:0.2].CGColor;
    _emailField.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
    _emailField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _emailField.autocorrectionType = UITextAutocorrectionTypeNo;
    _emailField.layer.cornerRadius = 4;
    _emailField.font = self.textFont;

    UIBarButtonItem *emailDoneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil)
                                                                        style:UIBarButtonItemStyleDone target:_emailField action:@selector(resignFirstResponder)];
    UIBarButtonItem *emailFlexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    UIToolbar *emailToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    emailToolbar.items = [NSArray arrayWithObjects:emailFlexibleSpace, emailDoneButton, nil];
    _emailField.inputAccessoryView = emailToolbar;

    [_boxView addSubview:_emailField];

    _poweredBy = [[UIView alloc] initWithFrame:CGRectMake(10.0f, 193.0f, 280.0f, 14.0f)];

    UILabel *powerByLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 80.0f, 14.0f)];
    powerByLabel.text = NSLocalizedString(@"Powered by", nil);
    powerByLabel.font = [UIFont boldSystemFontOfSize:12.0f];
    powerByLabel.textColor = [UIColor lightGrayColor];
    [_poweredBy addSubview:powerByLabel];

    UIButton *poweredByButton = [UIButton buttonWithType:UIButtonTypeCustom];
    poweredByButton.frame = CGRectMake(42.0f, 0.0f, 120.0f, 14.0f);
    poweredByButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.0f];
    [poweredByButton setTitle:@"Doorbell.io" forState:UIControlStateNormal];
    [poweredByButton setTitleColor:brandColor forState:UIControlStateNormal];

    [poweredByButton addTarget:self action:@selector(goToDoorbell:) forControlEvents:UIControlEventTouchUpInside];
    [_poweredBy addSubview:poweredByButton];

    [_boxView addSubview:_poweredBy];

    UIColor * cancelColor = [UIColor colorWithRed:0.95 green:0.2 blue:0.2 alpha:1];
    _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _cancelButton.frame = CGRectMake(0.0f, 211.0f, 150.0f, 44.0f);
    _cancelButton.titleLabel.font = [UIFont boldSystemFontOfSize:14.0f];
    //_cancelButton.backgroundColor = [UIColor lightGrayColor];
    [_cancelButton setTitle:NSLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];
    [_cancelButton setTitleColor:cancelColor forState:UIControlStateNormal];
    [_cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];

    [_cancelButton setBackgroundImage:[self imageWithColor:cancelColor] forState:UIControlStateHighlighted];
    [_cancelButton addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
    //_cancelButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    //_cancelButton.layer.borderWidth = .5f;


    _sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _sendButton.frame = CGRectMake(150.0f, 211.0f, 150.0f, 44.0f);
    _sendButton.titleLabel.font = [UIFont boldSystemFontOfSize:14.0f];
    [_sendButton setTitle:NSLocalizedString(@"Send", nil) forState:UIControlStateNormal];
    [_sendButton setTitleColor:brandColor forState:UIControlStateNormal];
    [_sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];

    [_sendButton setBackgroundImage:[self imageWithColor:brandColor] forState:UIControlStateHighlighted];
    [_sendButton addTarget:self action:@selector(send:) forControlEvents:UIControlEventTouchUpInside];
    //_sendButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    //_sendButton.layer.borderWidth = .5f;

    [_boxView addSubview:_cancelButton];
    [_boxView addSubview:_sendButton];
}

- (UIImage *)imageWithColor:(UIColor *)color
{
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}

- (void)verticalOffsetBy:(NSInteger)y
{
    [UIView animateWithDuration:0.25 animations:^{
        _boxView.transform = CGAffineTransformIdentity;
        _boxView.transform = CGAffineTransformMakeTranslation(0, y);
    }];
}

#pragma mark - UITextView Delegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    [self verticalOffsetBy:-90 - _verticleOffset];
    return YES;
}

-(void)textViewDidEndEditing:(UITextField *)textField
{
    [self verticalOffsetBy:0];
}

- (void)textViewDidChange:(UITextView *)textView
{
    if (textView.text.length > 0) {
        self.bodyPlaceHolderLabel.hidden = YES;
    }
    else {
        self.bodyPlaceHolderLabel.hidden = NO;
    }
}

#pragma mark - UITextField Delegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    [self verticalOffsetBy: -150 - _verticleOffset];
    return YES;
}

-(void)textFieldDidEndEditing:(UITextField *)textField
{
    [self verticalOffsetBy:0];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    [self send:textField];
    return NO;
}

@end
