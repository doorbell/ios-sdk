#import <UIKit/UIKit.h>

@interface DoorbellDialog : UIView <UITextViewDelegate, UITextFieldDelegate>

@property (strong, nonatomic)   UIColor *primaryColor;
@property (strong, nonatomic)   UIFont *titleFont;
@property (strong, nonatomic)   UIFont *textFont;

@property (strong, nonatomic)   UIView *boxView;
@property (readonly, nonatomic) NSString *bodyText;
@property (strong, nonatomic)   NSString *email;
@property (strong, nonatomic)   NSString *appID;
@property (assign, nonatomic)   BOOL showEmail;
@property (assign, nonatomic)   BOOL npsEnabled;
@property (assign, nonatomic)   int npsValue;
@property (assign, nonatomic)   BOOL showPoweredBy;
@property (assign, nonatomic)   BOOL sending;
@property (assign, nonatomic)   CGFloat verticleOffset;

@property (strong, nonatomic) id delegate;

- (id)initWithViewController:(UIViewController *)vc;
- (void)showMessageError:(NSString *)errorMessage;
- (void)createBoxSubviews;

@end


@protocol DoorbellDialogDelegate <NSObject>

- (void)dialogDidCancel:(DoorbellDialog*)dialog;
- (void)dialogDidSend:(DoorbellDialog*)dialog;

@end
