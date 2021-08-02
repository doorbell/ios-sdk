#import "Doorbell.h"
#import "DoorbellDialog.h"
#import "UIWindow+Doorbell.h"

NSString * const EndpointTemplate = @"https://doorbell.io/api/applications/%@/%@?sdk=ios&version=0.4.0&key=%@";
NSString * const UserAgent = @"Doorbell iOS SDK";

@interface Doorbell () <DoorbellDialogDelegate>

@property (copy, nonatomic)     DoorbellCompletionBlock block;//Block to give the result
@property (strong, nonatomic)   DoorbellDialog *dialog;
@property (strong, nonatomic)   NSMutableDictionary *properties;
@property (strong, nonatomic)   NSMutableArray *images;
@property (strong, nonatomic)   NSURLSession *session;
@property (strong, nonatomic)   NSString *imageBoundary;
@property (strong, nonatomic)   UIImage *screenshotImage;
@property (strong, nonatomic)   UIViewController *_vc;
@end

@implementation Doorbell
{
}

- (id)initWithApiKey:(NSString *)apiKey appId:(NSString *)appID
{
    self = [super init];
    if (self) {
        _animated = NO;
        _showEmail = YES;
        _showPoweredBy = YES;
        _nps = NO;
        self.apiKey = apiKey;
        self.appID = appID;
        self.name = @"";
        self.imageBoundary = @"FileUploadFormBoundaryForUsAll";
        self.language = [[[NSBundle mainBundle] preferredLocalizations] firstObject];

        self.properties = [[NSMutableDictionary alloc] init];
        self.images = [[NSMutableArray alloc] init];

        self.tags = [[NSMutableArray alloc] init];

        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        //sessionConfig.allowsCellularAccess = NO;
        [sessionConfig setHTTPAdditionalHeaders:@{@"Content-Type": @"application/json",
                                                  @"Accept": @"application/json",
                                                  @"User-Agent": UserAgent
                                                  }];
        sessionConfig.timeoutIntervalForRequest = 30.0;
        sessionConfig.timeoutIntervalForResource = 60.0;
        sessionConfig.HTTPMaximumConnectionsPerHost = 1;
        _session = [NSURLSession sessionWithConfiguration:sessionConfig];

        [self addPropertyWithName:@"Model" AndValue:[self deviceName]];
        NSString *osVersion = [[UIDevice currentDevice] systemVersion];
        [self addPropertyWithName:@"iOS Version" AndValue:osVersion];

        NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        [self addPropertyWithName:@"App Version" AndValue:appVersion];

        NSString *appBuild = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];
        [self addPropertyWithName:@"App Build" AndValue:appBuild];
    }
    return self;
}

+ (Doorbell*)doorbellWithApiKey:(NSString *)apiKey appId:(NSString *)appID
{
    return [[[self class] alloc] initWithApiKey:apiKey appId:appID];
}

- (BOOL)checkCredentials
{
    if (self.appID.length == 0 || self.apiKey.length == 0) {
        NSError *error = [NSError errorWithDomain:@"doorbell.io" code:2 userInfo:@{NSLocalizedDescriptionKey: @"Doorbell credentials could not be found (key, appID)."}];
        if (self.block != nil) {
            self.block(error, YES);
        }
        return NO;
    }

    return YES;
}

-(UIImage *)takeScreenshot
{
    // create graphics context with screen size
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    UIGraphicsBeginImageContext(screenRect.size);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [[UIColor blackColor] set];
    CGContextFillRect(ctx, screenRect);

    // grab reference to our window
    UIWindow *window = self.keyWindow;

    // transfer content into our context
    [window.layer renderInContext:ctx];
    UIImage *screenshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return screenshot;
}

-(UIWindow *)keyWindow
{
    NSArray *windows = [[UIApplication sharedApplication]windows];

    for (UIWindow *window in windows) {
        if (window.isKeyWindow) {
            return window;
        }
    }

    return nil;
}


- (void)showFeedbackDialogInViewController:(UIViewController *)vc completion:(DoorbellCompletionBlock)completion
{
    if (![self checkCredentials]) {
        return;
    }

    if (!vc || ![vc isKindOfClass:[UIViewController class]]) {
        NSError *error = [NSError errorWithDomain:@"doorbell.io" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Doorbell needs a ViewController"}];
        completion(error, YES);
        return;
    }

    if (self.screenshot) {
        self.screenshotImage = [self takeScreenshot];
    }

    [self addPropertyWithName:@"ViewController" AndValue:NSStringFromClass([vc class])];
    
    self.block = completion;
    self.dialog = [[DoorbellDialog alloc] initWithViewController:vc];
    self.dialog.appID = self.appID;
    self.dialog.primaryColor = self.primaryColor;
    self.dialog.titleFont = self.titleFont;
    self.dialog.textFont = self.textFont;
    self.dialog.showEmail = self.showEmail;
    self.dialog.npsEnabled = self.nps;
    self.dialog.showPoweredBy = self.showPoweredBy;
    [self.dialog createBoxSubviews]; // init UI
    self.dialog.delegate = self;
    self.dialog.email = self.email;
    self.dialog.tag = self.viewTag;
    self.dialog.verticleOffset = self.verticleOffset;

    self.dialog.alpha = 0;
    self.dialog.boxView.transform = CGAffineTransformMakeTranslation(0, -20);

    [vc.view addSubview:self.dialog];

    float duration = _animated ? 0.3 : 0;
    [UIView animateWithDuration:duration animations:^{
        self.dialog.alpha = 1;
        self.dialog.boxView.transform = CGAffineTransformIdentity;
    }];

    //Open - Request sent when the form is displayed to the user.
    [self sendOpen];
}

- (void)startShakeListener:(DoorbellCompletionBlock)completion
{
    self.block = completion;
    
    __block Doorbell* db = self;

    [[NSNotificationCenter defaultCenter] addObserverForName:@"UIDoorbellWindowDidShake"
                        object:nil
                        queue:nil
                        usingBlock:^(NSNotification *notification){
        UIViewController *vc = self.keyWindow.rootViewController;
        
        [db showFeedbackDialogInViewController:vc completion:db.block];
    }];
}

- (void)startShakeListenerWithViewController:(UIViewController *)vc completion:(DoorbellCompletionBlock)completion
{
    self.block = completion;
    self._vc = vc;
    
    __block Doorbell* db = self;

    [[NSNotificationCenter defaultCenter] addObserverForName:@"UIDoorbellWindowDidShake"
                        object:nil
                        queue:nil
                        usingBlock:^(NSNotification *notification){
        [db showFeedbackDialogInViewController:db._vc completion:db.block];
    }];
}

- (void)showFeedbackDialogWithCompletionBlock:(DoorbellCompletionBlock)completion
{
    self.block = completion;
    UIWindow *currentWindow = self.keyWindow;
    self.dialog = [[DoorbellDialog alloc] initWithFrame:currentWindow.frame];
    self.dialog.appID = self.appID;
    self.dialog.delegate = self;
    self.dialog.showEmail = self.showEmail;
    self.dialog.npsEnabled = self.nps;
    self.dialog.email = self.email;
    self.dialog.showPoweredBy = self.showPoweredBy;
    self.dialog.tag = self.viewTag;
    self.dialog.verticleOffset = self.verticleOffset;
    [currentWindow addSubview:self.dialog];
}

#pragma mark - Selectors

- (void)fieldError:(NSString*)validationError
{
    [self.dialog showMessageError:validationError];
    self.dialog.sending = NO;
}

- (void)generalError:(NSString *)errorMessage
{
    [self.dialog showMessageError:errorMessage];
    self.dialog.sending = NO;
}

- (void)finish
{
    float duration = _animated ? 0.3 : 0;
    [UIView animateWithDuration:duration animations:^{
        self.dialog.alpha = 0;
        self.dialog.boxView.transform = CGAffineTransformMakeTranslation(0, -20);
    } completion:^(BOOL finished) {
        [self.dialog removeFromSuperview];
        if (self.block != nil) {
            self.block(nil, NO);
        }
    }];
}

#pragma mark - Dialog delegate

- (void)dialogDidCancel:(DoorbellDialog*)dialog
{
    float duration = _animated ? 0.3 : 0;
    [UIView animateWithDuration:duration animations:^{
        self.dialog.alpha = 0;
        self.dialog.boxView.transform = CGAffineTransformMakeTranslation(0, -20);
    } completion:^(BOOL finished) {
        [self.dialog removeFromSuperview];
        if (self.block != nil) {
            self.block(nil, YES);
        }
    }];
}

- (void)dialogDidSend:(DoorbellDialog*)dialog
{
    self.dialog.sending = YES;
    [self sendSubmit:dialog.bodyText email:dialog.email];
    //    [dialog removeFromSuperview];
    //    self.block(nil, YES);
}

#pragma mark - Endpoints

- (void)sendOpen
{
    if (![self checkCredentials]) {
        return;
    }

    NSMutableURLRequest *openRequest = [self createRequestWithType:@"open"];

    NSURLSessionDataTask *openTask = [_session dataTaskWithRequest:openRequest
                                                 completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                                     if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                                                         NSHTTPURLResponse *httpResp = (id)response;
                                                         if (httpResp.statusCode != 201) {
                                                             NSLog(@"%d: There was an error trying to connect with doorbell. Open called failed", (int)httpResp.statusCode);
                                                             NSLog(@"%@", [NSString stringWithUTF8String:data.bytes]);
                                                         }
                                                     }
                                                 }];
    [openTask resume];
}

- (void)submitFeedback:(NSString *)message email:(NSString *)email completion:(DoorbellCompletionBlock)completion
{
    self.block = completion;
    
    [self sendSubmit:message email:email];
}

- (void)sendSubmit:(NSString*)message email:(NSString*)email
{
    if (self.images.count > 0) {
        [self uploadImagesWithMessage:message WithEmail:email];
    }
    else {
        NSData *jsonData = [self createSubmitDataWithMessage:message
                                                   WithEmail:email
                                           WithAttachmentIds:nil];

        NSMutableURLRequest *submitRequest = [self createRequestWithType:@"submit"];
        [self sendUploadRequest:submitRequest WithData:jsonData];
    }
}

- (NSData *)createSubmitDataWithMessage:(NSString *)message
                              WithEmail:(NSString *)email
                      WithAttachmentIds:(NSArray *)attachmentIds {
    NSMutableDictionary *submitData = [[NSMutableDictionary alloc] init];
    [submitData setValue:message forKey:@"message"];
    [submitData setValue:email forKey:@"email"];
    [submitData setValue:self.properties forKey:@"properties"];
    [submitData setValue:self.name forKey:@"name"];
    [submitData setValue:self.language forKey:@"language"];
    [submitData setValue:self.tags forKey:@"tags"];

    if (self.nps && self.dialog.npsValue >= 0) {
        NSNumber *npsValue = [NSNumber numberWithInt:self.dialog.npsValue];
        [submitData setValue:npsValue forKey:@"nps"];
    }
    
    if (self.screenshotImage != nil) {
        NSData *imageData = UIImagePNGRepresentation(self.screenshotImage);

        NSString *screenshotDataURI = [imageData base64EncodedStringWithOptions:0];
        
        [submitData setValue:screenshotDataURI forKey:@"ios_screenshot"];
    }

    if (attachmentIds != nil) {
        [submitData setValue:attachmentIds forKey:@"attachments"];
    }

    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:submitData
                                                       options:(NSJSONWritingOptions)0
                                                         error:&error];

    if (! jsonData) {
        NSLog(@"JSON Encoding error: %@", error.localizedDescription);
        return nil;
    }

    return jsonData;
}

- (NSMutableURLRequest *)createRequestWithType:(NSString *)type {
    NSString *query = [NSString stringWithFormat:EndpointTemplate, self.appID, type, self.apiKey];
    NSURL *url = [NSURL URLWithString:query];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    if ([type isEqualToString:@"submit"] ||
        [type isEqualToString:@"open"] ||
        [type isEqualToString:@"upload"]) {
        request.HTTPMethod = @"POST";
    }
    return request;
}

- (void)sendUploadRequest:(NSMutableURLRequest *)request WithData:(NSData *)data {
    NSURLSessionUploadTask *uploadTask = [_session uploadTaskWithRequest:request
                                                                fromData:data
                                                       completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                                           dispatch_async(dispatch_get_main_queue(), ^{
                                                               NSString *content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                                               NSLog(@"Response data: %@", content);
                                                               
                                                               if ([data length] > 0 && error == nil)
                                                               {
                                                                   [self manageSubmitResponse:response content:content];
                                                               }
                                                               else if ([data length] == 0 && error == nil)
                                                               {
                                                                   [self generalError:@"No response, please try again!"];

                                                                   NSError *doorbellError = [NSError errorWithDomain:@"doorbell.io" code:3 userInfo:@{NSLocalizedDescriptionKey: @"Something went wrong, please try again"}];

                                                                   self.block(doorbellError , YES);
                                                               }
                                                               else if (error != nil)
                                                               {
                                                                   [self generalError:[[NSString alloc] initWithFormat:@"Error, please try again (%@)", error.localizedDescription] ];

                                                                   self.block(error, YES);
                                                               }
                                                           });
                                                       }];
    [uploadTask resume];
}

- (void)uploadImagesWithMessage:(NSString *)message WithEmail:(NSString *)email {
    NSURLSessionConfiguration *conf = [NSURLSessionConfiguration defaultSessionConfiguration];
    [conf setHTTPAdditionalHeaders:@{@"Content-Type": [NSString stringWithFormat:@"multipart/form-data; boundary=%@", self.imageBoundary],
                                     @"Accept": @"application/json",
                                     @"User-Agent": UserAgent
                                     }];
    NSURLSession *uploadSession = [NSURLSession sessionWithConfiguration:conf];

    NSMutableURLRequest *uploadRequest = [self createRequestWithType:@"upload"];

    __block Doorbell *weakSelf = self;
    NSURLSessionUploadTask *uploadTask = [uploadSession uploadTaskWithRequest:uploadRequest
                                                                     fromData:[self createImageUploadBodyData]
                                                            completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                                                if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                                                                    NSHTTPURLResponse *httpResp = (id)response;
                                                                    NSString *content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                                                    NSLog(@"%d:%@", (int)httpResp.statusCode, content);
                                                                    NSError *error;
                                                                    NSArray *attachmentIds = [NSJSONSerialization JSONObjectWithData:data
                                                                                                                             options:NSJSONReadingAllowFragments
                                                                                                                               error:&error];
                                                                    if (attachmentIds) {
                                                                        NSData *jsonData = [weakSelf createSubmitDataWithMessage:message
                                                                                                                       WithEmail:email
                                                                                                               WithAttachmentIds:attachmentIds];

                                                                        NSMutableURLRequest *submitRequest = [weakSelf createRequestWithType:@"submit"];
                                                                        [weakSelf sendUploadRequest:submitRequest WithData:jsonData];
                                                                    }
                                                                    else {
                                                                        dispatch_async(dispatch_get_main_queue(), ^{
                                                                            [self manageSubmitResponse:httpResp content:content];
                                                                        });
                                                                    }
                                                                }
                                                            }];
    [uploadTask resume];
}

// Accepts an array of Dictionaries
// @{@"data": NSDataOfImage, @"name": nameOfImage}
- (NSData *)createImageUploadBodyData {
    NSMutableData *body = [NSMutableData data];
    for (NSDictionary *image in self.images) {
        if (image[@"data"] && image[@"name"]) {
            [body appendData:[[NSString stringWithFormat:@"--%@\r\n", self.imageBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@.jpg\"\r\n", image[@"name"], image[@"name"]] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[@"Content-Type: image/jpeg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:image[@"data"]];
            [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
        }
    }
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", self.imageBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    return body;
}

- (void)addPropertyWithName:(NSString*)name AndValue:(id)value {
    [self.properties setValue:value forKey:name];
}

- (void)addImage:(UIImage *)image WithName:(NSString *)name {
    if (image && name) {
        NSData *imgData = UIImageJPEGRepresentation(image, 0.5);
        NSDictionary *img = @{@"data": imgData, @"name": name};
        [self.images addObject:img];
    }
}

- (void)manageSubmitResponse:(NSURLResponse*)response content:(NSString*)content
{
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResp = (id)response;
        switch (httpResp.statusCode) {
            case 201:
                [self finish];
                break;
            case 400:
                [self fieldError:content];
                self.block([NSError errorWithDomain:@"doorbell.io" code:3 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:content, (int)httpResp.statusCode, content]}] , YES);
                break;
            default:
                [self generalError:content];
                self.block([NSError errorWithDomain:@"doorbell.io" code:3 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"%d: HTTP unexpected\n%@", (int)httpResp.statusCode, content]}] , YES);
                break;
        }
        
        return;
    }

    [self generalError:content];
    self.block([NSError errorWithDomain:@"doorbell.io" code:3 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"HTTP unexpected\n%@", content]}] , YES);
}

// Copied from https://stackoverflow.com/a/20062141/349012
- (NSString*) deviceName
{
    struct utsname systemInfo;

    uname(&systemInfo);

    NSString* code = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];

    static NSDictionary* deviceNamesByCode = nil;

    if (!deviceNamesByCode) {

        deviceNamesByCode = @{@"i386"      : @"Simulator",
                              @"x86_64"    : @"Simulator",
                              @"iPod1,1"   : @"iPod Touch",        // (Original)
                              @"iPod2,1"   : @"iPod Touch",        // (Second Generation)
                              @"iPod3,1"   : @"iPod Touch",        // (Third Generation)
                              @"iPod4,1"   : @"iPod Touch",        // (Fourth Generation)
                              @"iPod7,1"   : @"iPod Touch",        // (6th Generation)       
                              @"iPhone1,1" : @"iPhone",            // (Original)
                              @"iPhone1,2" : @"iPhone",            // (3G)
                              @"iPhone2,1" : @"iPhone",            // (3GS)
                              @"iPad1,1"   : @"iPad",              // (Original)
                              @"iPad2,1"   : @"iPad 2",            //
                              @"iPad3,1"   : @"iPad",              // (3rd Generation)
                              @"iPhone3,1" : @"iPhone 4",          // (GSM)
                              @"iPhone3,3" : @"iPhone 4",          // (CDMA/Verizon/Sprint)
                              @"iPhone4,1" : @"iPhone 4S",         //
                              @"iPhone5,1" : @"iPhone 5",          // (model A1428, AT&T/Canada)
                              @"iPhone5,2" : @"iPhone 5",          // (model A1429, everything else)
                              @"iPad3,4"   : @"iPad",              // (4th Generation)
                              @"iPad2,5"   : @"iPad Mini",         // (Original)
                              @"iPhone5,3" : @"iPhone 5c",         // (model A1456, A1532 | GSM)
                              @"iPhone5,4" : @"iPhone 5c",         // (model A1507, A1516, A1526 (China), A1529 | Global)
                              @"iPhone6,1" : @"iPhone 5s",         // (model A1433, A1533 | GSM)
                              @"iPhone6,2" : @"iPhone 5s",         // (model A1457, A1518, A1528 (China), A1530 | Global)
                              @"iPhone7,1" : @"iPhone 6 Plus",     //
                              @"iPhone7,2" : @"iPhone 6",          //
                              @"iPhone8,1" : @"iPhone 6S",         //
                              @"iPhone8,2" : @"iPhone 6S Plus",    //
                              @"iPhone8,4" : @"iPhone SE",         //
                              @"iPhone9,1" : @"iPhone 7",          //
                              @"iPhone9,3" : @"iPhone 7",          //
                              @"iPhone9,2" : @"iPhone 7 Plus",     //
                              @"iPhone9,4" : @"iPhone 7 Plus",     //
                              @"iPhone10,1": @"iPhone 8",          // CDMA
                              @"iPhone10,4": @"iPhone 8",          // GSM
                              @"iPhone10,2": @"iPhone 8 Plus",     // CDMA
                              @"iPhone10,5": @"iPhone 8 Plus",     // GSM
                              @"iPhone10,3": @"iPhone X",          // CDMA
                              @"iPhone10,6": @"iPhone X",          // GSM
                              @"iPhone11,2": @"iPhone XS",         //
                              @"iPhone11,4": @"iPhone XS Max",     //
                              @"iPhone11,6": @"iPhone XS Max",     // China
                              @"iPhone11,8": @"iPhone XR",         //

                              @"iPad4,1"   : @"iPad Air",          // 5th Generation iPad (iPad Air) - Wifi
                              @"iPad4,2"   : @"iPad Air",          // 5th Generation iPad (iPad Air) - Cellular
                              @"iPad4,4"   : @"iPad Mini",         // (2nd Generation iPad Mini - Wifi)
                              @"iPad4,5"   : @"iPad Mini",         // (2nd Generation iPad Mini - Cellular)
                              @"iPad4,7"   : @"iPad Mini",         // (3rd Generation iPad Mini - Wifi (model A1599))
                              @"iPad6,7"   : @"iPad Pro (12.9\")", // iPad Pro 12.9 inches - (model A1584) 
                              @"iPad6,8"   : @"iPad Pro (12.9\")", // iPad Pro 12.9 inches - (model A1652) 
                              @"iPad6,3"   : @"iPad Pro (9.7\")",  // iPad Pro 9.7 inches - (model A1673)
                              @"iPad6,4"   : @"iPad Pro (9.7\")"   // iPad Pro 9.7 inches - (models A1674 and A1675)
                              };
    }

    NSString* deviceName = [deviceNamesByCode objectForKey:code];

    if (!deviceName) {
        // Not found on database. At least guess main device type from string contents:

        if ([code rangeOfString:@"iPod"].location != NSNotFound) {
            deviceName = @"iPod Touch";
        }
        else if([code rangeOfString:@"iPad"].location != NSNotFound) {
            deviceName = @"iPad";
        }
        else if([code rangeOfString:@"iPhone"].location != NSNotFound){
            deviceName = @"iPhone";
        }
        else {
            deviceName = @"Unknown";
        }
    }

    return deviceName;
}

@end
