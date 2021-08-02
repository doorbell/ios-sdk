#import "DoorbellDialog.h"
#import <QuartzCore/QuartzCore.h>

NSString * const DoorbellSite = @"https://doorbell.io/?utm_source=feedback_form&utm_medium=web_sdk&utm_campaign=application_%@";

@interface DoorbellDialog ()

@property (strong, nonatomic) UITextView *bodyView;
@property (strong, nonatomic) UITextField *emailField;
@property (strong, nonatomic) UIButton *cancelButton;
@property (strong, nonatomic) UIButton *sendButton;
@property (strong, nonatomic) UIView *npsContainer;
@property (strong, nonatomic) UISlider *npsSlider;
@property (strong, nonatomic) UIImage *npsSliderThumbImage;
@property (strong, nonatomic) UIColor *npsSliderMinimumTrackTint;
@property (assign, nonatomic) BOOL npsSliderThumbVisible;
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
        _npsEnabled = NO;
        _sending = NO;
        _npsValue = -1;
        
        // Initialization code
        self.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.3];
        self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin;
        CGRect boxFrame;
        boxFrame.size = CGSizeMake(300, 255);
        boxFrame = [self calculateNewBoxFrame:boxFrame];
        _boxView = [[UIView alloc] initWithFrame:boxFrame];
        if (@available(iOS 13.0, *)) {
            _boxView.backgroundColor = [UIColor systemBackgroundColor];
        } else {
            _boxView.backgroundColor = [UIColor whiteColor];
        }
        _boxView.layer.masksToBounds = NO;
        _boxView.layer.cornerRadius = 4.0f;
        //_boxView.layer.borderColor = [UIColor blackColor].CGColor;
        //_boxView.layer.borderWidth = 1.0f;
        _boxView.layer.shadowColor = [UIColor darkGrayColor].CGColor;
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
    NSString *doorbellURLWithUTM = [NSString stringWithFormat:DoorbellSite, self.appID];
    NSURL *doorbellURL = [NSURL URLWithString:doorbellURLWithUTM];
    if (@available(iOS 10.0, *)) {
        [[UIApplication sharedApplication] openURL:doorbellURL options:@{} completionHandler:^(BOOL success) {
            //        if (success) {
            //             NSLog(@"Opened url");
            //        }
        }];
    } else {
        // Fallback on earlier versions
        [[UIApplication sharedApplication] openURL:doorbellURL];
    }
}

- (void)send:(id)sender
{
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

- (void)showMessageError:(NSString *)errorMessage
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil) message: NSLocalizedString(errorMessage, nil) preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:nil];

    [alert addAction: ok];
    
    [self.parentViewController presentViewController:alert animated:YES completion:nil];
}

- (void)setShowEmail:(BOOL)showEmail
{
    _showEmail = showEmail;
    _emailField.hidden = !showEmail;
    [self layoutSubviews];
}

- (void)setEnableNPS:(BOOL)npsEnabled
{
    _npsEnabled = npsEnabled;
    _npsContainer.hidden = !npsEnabled;
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
    if (_npsEnabled) {
        _npsContainer.hidden = sending;
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
    boxFrame.origin.x = (self.frame.size.width - boxFrame.size.width) / 2;
    boxFrame.origin.y = ((self.frame.size.height - boxFrame.size.height) / 2) + _verticleOffset;

    return boxFrame;
}

- (void)layoutSubviews
{
    float offsetY = _bodyView.frame.origin.y + _bodyView.frame.size.height + 10.0f;
    int padding = 10;
    
    if (_showEmail) {
        _emailField.frame = CGRectMake(10.0f, offsetY, 280.0f, 30.0f);
        offsetY += _emailField.frame.size.height + padding;
    }

    if (_npsEnabled) {
        _npsContainer.frame = CGRectMake(10.0f, offsetY, 280.0f, 64.0f);
        offsetY += _npsContainer.frame.size.height + padding;
    }

    if (_showPoweredBy) {
        _poweredBy.frame = CGRectMake(10.0f, offsetY, 280.0f, 14.0f);
        offsetY += _poweredBy.frame.size.height + padding;
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
    titleLabel.font = self.titleFont ? self.titleFont : [UIFont boldSystemFontOfSize:18.0f];

    titleLabel.textAlignment = NSTextAlignmentLeft;
    titleLabel.textColor = brandColor;

    [_boxView addSubview:titleLabel];

    CALayer *line = [CALayer layer];
    line.frame = CGRectMake(0, 35.0f, 300.0f, 1.0f);
    line.backgroundColor = brandColor.CGColor;
    [_boxView.layer addSublayer:line];

    _bodyView = [[UITextView alloc] initWithFrame:CGRectMake(10.0f, 45.0f, 280.0f, 100)];
    _bodyView.delegate = self;
    if (@available(iOS 13.0, *)) {
        _bodyView.backgroundColor = [UIColor systemBackgroundColor];
        //    _bodyView.textColor = [UIColor darkTextColor];
    } else {
        _bodyView.backgroundColor = [UIColor whiteColor];
        _bodyView.textColor = [UIColor darkTextColor];
    }
    _bodyView.font = self.textFont ? self.textFont : [UIFont systemFontOfSize:16.0f];

    _bodyView.dataDetectorTypes = UIDataDetectorTypeNone;
    _bodyView.layer.borderColor = [UIColor systemGrayColor].CGColor;
    _bodyView.layer.borderWidth  = 1.0 / [UIScreen mainScreen].scale;
    _bodyView.keyboardAppearance = UIKeyboardAppearanceAlert;
    _bodyView.layer.cornerRadius = 4;

    UIBarButtonItem *bodyDoneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil) style:UIBarButtonItemStyleDone target:_bodyView action:@selector(resignFirstResponder)];
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
    
    NSMutableAttributedString * emailAstring = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"Your email address", nil) attributes:nil];
    if (self.textFont != nil) {
        [emailAstring addAttribute:NSFontAttributeName value:self.textFont range:NSMakeRange(0, emailAstring.length)];
    }
    
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
    _emailField.layer.borderColor = [UIColor systemGrayColor].CGColor;
    _emailField.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
    _emailField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _emailField.autocorrectionType = UITextAutocorrectionTypeNo;
    _emailField.layer.cornerRadius = 4;
    if (@available(iOS 13.0, *)) {
        _emailField.backgroundColor = [UIColor systemBackgroundColor];
    }
    _emailField.font = self.textFont ? self.textFont : [UIFont systemFontOfSize:14.0f];

    UIBarButtonItem *emailDoneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil) style:UIBarButtonItemStyleDone target:_emailField action:@selector(resignFirstResponder)];
    UIBarButtonItem *emailFlexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    UIToolbar *emailToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    emailToolbar.items = [NSArray arrayWithObjects:emailFlexibleSpace, emailDoneButton, nil];
    _emailField.inputAccessoryView = emailToolbar;

    _emailField.hidden = !_showEmail;

    [_boxView addSubview:_emailField];

    _npsContainer = [[UIView alloc] initWithFrame:CGRectMake(10.0f, 0, 280.0f, 64.0f)];
    _npsContainer.hidden = !_npsEnabled;
    [_boxView addSubview:_npsContainer];
    
    UILabel *npsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 280.0f, 16.0f)];
    npsLabel.text = NSLocalizedString(@"How likely are you to recommend us to a friend?", nil);
    npsLabel.font = self.textFont ? self.textFont : [UIFont systemFontOfSize:12.0f];
    [_npsContainer addSubview:npsLabel];

    _npsSlider = [[UISlider alloc] initWithFrame:CGRectMake(0.0f, 24.0f, 280.0f, 24.0f)];
    _npsSlider.minimumValue = 0;
    _npsSlider.maximumValue = 10;
    _npsSlider.value = 0;
    _npsSlider.continuous = NO;
    
    // Back them up, so we can reset it when the value starts changing
    _npsSliderThumbImage = _npsSlider.currentThumbImage;
    _npsSliderMinimumTrackTint = _npsSlider.minimumTrackTintColor;
    
    [_npsSlider setThumbImage:[[UIImage alloc] init] forState:UIControlStateNormal];
    [_npsSlider setMinimumTrackTintColor:_npsSlider.maximumTrackTintColor];
    [_npsSlider addTarget:self action:@selector(npsSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(npsSliderTapAndSlide:)];
    longPress.minimumPressDuration = 0;
    [_npsSlider addGestureRecognizer:longPress];
    
    _npsSlider.backgroundColor = UIColor.clearColor;
    
    [_npsContainer addSubview:_npsSlider];

    UILabel *npsRatingBad = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 54.0f, 140.0f, 16.0f)];
    npsRatingBad.text = NSLocalizedString(@"0", nil);
    npsRatingBad.font = self.textFont ? self.textFont : [UIFont systemFontOfSize:12.0f];
    [_npsContainer addSubview:npsRatingBad];
    
    UILabel *npsRatingGood = [[UILabel alloc] initWithFrame:CGRectMake(140.0f, 54.0f, 140.0f, 16.0f)];
    npsRatingGood.text = NSLocalizedString(@"10", nil);
    npsRatingGood.font = self.textFont ? self.textFont : [UIFont systemFontOfSize:12.0f];
    npsRatingGood.textAlignment = NSTextAlignmentRight;
    [_npsContainer addSubview:npsRatingGood];
    
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

    _poweredBy.hidden = !_showPoweredBy;
    
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
    
    [self layoutSubviews];
    _boxView.frame = [self calculateNewBoxFrame:_boxView.frame];
}

- (void) showNPSSliderThumb
{
    if (_npsSliderThumbVisible) {
        // Already visible, don't do anything
        return;
    }
    
    [_npsSlider setMinimumTrackTintColor:_npsSliderMinimumTrackTint];
    [_npsSlider setThumbImage:_npsSliderThumbImage forState:UIControlStateNormal];
    
    _npsSliderThumbVisible = true;
}

- (void) npsSliderValueChanged:(UISlider *)slider
{
    if (!_npsSliderThumbVisible) {
        [self showNPSSliderThumb];
    }

//    NSLog(@"Slider value updating: %f, rounded: %d", slider.value, (int)roundf(slider.value));
    
    float roundedValue = roundf(slider.value);
    _npsValue = (int)roundedValue;

    // Animate the "snap" to the right value
    [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [slider setValue:roundedValue animated:YES];
    } completion:nil];
}

// Inspiration from here: https://stackoverflow.com/a/22982080/349012
- (void)npsSliderTapAndSlide:(UILongPressGestureRecognizer*)gesture
{
    CGPoint pt = [gesture locationInView: _npsSlider];
    CGFloat thumbWidth = [self thumbRect].size.width;
    CGFloat value;
    
    if(pt.x <= [self thumbRect].size.width/2.0)
        value = _npsSlider.minimumValue;
    else if(pt.x >= _npsSlider.bounds.size.width - thumbWidth/2.0)
        value = _npsSlider.maximumValue;
    else {
        CGFloat percentage = (pt.x - thumbWidth/2.0)/(_npsSlider.bounds.size.width - thumbWidth);
        CGFloat delta = percentage * (_npsSlider.maximumValue - _npsSlider.minimumValue);
        value = _npsSlider.minimumValue + delta;
    }
    
    // To trigger showing the thumb
    if (!_npsSliderThumbVisible) {
        [self showNPSSliderThumb];
    }

    [_npsSlider setValue:value];
    
    // If we want it behaving like continuous=YES
//    if(gesture.state == UIGestureRecognizerStateChanged) {
//        [_npsSlider sendActionsForControlEvents:UIControlEventValueChanged];
//    }

    // If we want it behaving like continuous=NO
    if(gesture.state == UIGestureRecognizerStateEnded) {
        [_npsSlider sendActionsForControlEvents:UIControlEventValueChanged];
    }
}

- (CGRect)thumbRect {
    CGRect trackRect = [_npsSlider trackRectForBounds:_npsSlider.bounds];
    return [_npsSlider thumbRectForBounds:_npsSlider.bounds trackRect:trackRect value:_npsSlider.value];
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
        self->_boxView.transform = CGAffineTransformIdentity;
        self->_boxView.transform = CGAffineTransformMakeTranslation(0, y);
    }];
}

#pragma mark - UITextView Delegate

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    [self verticalOffsetBy:-90 - _verticleOffset];
}

-(void)textViewDidEndEditing:(UITextView *)textView
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

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self verticalOffsetBy: -150 - _verticleOffset];
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
