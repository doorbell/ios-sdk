#import <UIKit/UIKit.h>


typedef void (^DoorbellCompletionBlock)(NSError *error, BOOL isCancelled);


@interface Doorbell : NSObject

@property (strong, nonatomic)   NSString *apiKey;
@property (strong, nonatomic)   NSString *appID;
@property (strong, nonatomic)   NSString *email;
@property (strong, nonatomic)   NSString *name;
@property (assign, nonatomic)   BOOL showEmail;
@property (assign, nonatomic)   BOOL showPoweredBy;

- (id)initWithApiKey:(NSString *)apiKey appId:(NSString *)appID;

+ (Doorbell*)doorbellWithApiKey:(NSString *)apiKey appId:(NSString *)appID;

- (void)showFeedbackDialogInViewController:(UIViewController *)vc completion:(DoorbellCompletionBlock)completion;

- (void)addPropertyWithName:(NSString*)name AndValue:(id)value;

@end
