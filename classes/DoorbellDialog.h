#import <UIKit/UIKit.h>

@interface DoorbellDialog : UIView <UITextViewDelegate, UITextFieldDelegate>

@property (readonly, nonatomic) NSString *bodyText;
@property (strong, nonatomic) NSString *email;
@property (assign, nonatomic)   BOOL showEmail;
@property (assign, nonatomic)   BOOL showPoweredBy;
@property (assign, nonatomic)   BOOL sending;

@property (strong, nonatomic) id delegate;

- (id)initWithViewController:(UIViewController *)vc;

- (void)highlightEmailEmpty;
- (void)highlightEmailInvalid;
- (void)highlightMessageEmpty;

@end


@protocol DoorbellDialogDelegate <NSObject>

- (void)dialogDidCancel:(DoorbellDialog*)dialog;
- (void)dialogDidSend:(DoorbellDialog*)dialog;

@end
