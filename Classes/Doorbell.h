#import <UIKit/UIKit.h>
#import <sys/utsname.h>

typedef void (^DoorbellCompletionBlock)(NSError *error, BOOL isCancelled);


@interface Doorbell : NSObject

@property (strong, nonatomic)   UIColor * primaryColor;
@property (strong, nonatomic)   UIFont * titleFont;
@property (strong, nonatomic)   UIFont * textFont;

@property (strong, nonatomic)   NSString *apiKey;
@property (strong, nonatomic)   NSString *appID;
@property (strong, nonatomic)   NSString *email;
@property (strong, nonatomic)   NSString *name;
@property (strong, nonatomic)   NSString *language;
@property (strong, nonatomic)   NSMutableArray *tags;
@property (assign, nonatomic)   BOOL screenshot;
@property (assign, nonatomic)   BOOL nps;
@property (assign, nonatomic)   BOOL showEmail;
@property (assign, nonatomic)   BOOL showPoweredBy;
@property (assign, nonatomic)   BOOL animated;
@property (assign, nonatomic)   CGFloat verticleOffset;
@property (assign, nonatomic)   NSInteger viewTag;

- (id)initWithApiKey:(NSString *)apiKey appId:(NSString *)appID;

+ (Doorbell*)doorbellWithApiKey:(NSString *)apiKey appId:(NSString *)appID;

- (void)showFeedbackDialogInViewController:(UIViewController *)vc completion:(DoorbellCompletionBlock)completion;

- (void)addPropertyWithName:(NSString*)name AndValue:(id)value;

- (void)addImage:(UIImage *)image WithName:(NSString *)name;

- (void)submitFeedback:(NSString*)message email:(NSString*)email completion:(DoorbellCompletionBlock)completion;

- (void)startShakeListenerWithViewController:(UIViewController *)vc completion:(DoorbellCompletionBlock)completion;

- (void)startShakeListener:(DoorbellCompletionBlock)completion;

@end
