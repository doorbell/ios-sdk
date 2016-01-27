#import "Doorbell.h"
#import "DoorbellDialog.h"

NSString * const EndpointTemplate = @"https://doorbell.io/api/applications/%@/%@?key=%@";
NSString * const UserAgent = @"Doorbell iOS SDK";

@interface Doorbell () <DoorbellDialogDelegate>

@property (copy, nonatomic)     DoorbellCompletionBlock block;//Block to give the result
@property (strong, nonatomic)   DoorbellDialog *dialog;
@property (strong, nonatomic)   NSMutableDictionary *properties;
@property (strong, nonatomic)   NSMutableArray *images;
@property (strong, nonatomic)   NSURLSession *session;
@property (strong, nonatomic)   NSString *imageBoundary;
@end

@implementation Doorbell

- (id)initWithApiKey:(NSString *)apiKey appId:(NSString *)appID
{
    self = [super init];
    if (self) {
        _showEmail = YES;
        _showPoweredBy = YES;
        self.apiKey = apiKey;
        self.appID = appID;
        self.name = @"";
        self.imageBoundary = @"FileUploadFormBoundaryForUsAll";

        self.properties = [[NSMutableDictionary alloc] init];
        self.images = [[NSMutableArray alloc] init];

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
        NSError *error = [NSError errorWithDomain:@"doorbell.io" code:2 userInfo:@{NSLocalizedDescriptionKey: @"Doorbell. Credentials could not be founded (key, appID)."}];
        self.block(error, YES);
        return NO;
    }

    return YES;
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

    self.block = completion;
    self.dialog = [[DoorbellDialog alloc] initWithViewController:vc];
    self.dialog.delegate = self;
    self.dialog.showEmail = self.showEmail;
    self.dialog.email = self.email;
    self.dialog.showPoweredBy = self.showPoweredBy;
    [vc.view addSubview:self.dialog];

    //Open - Request sent when the form is displayed to the user.
    [self sendOpen];
}

- (void)showFeedbackDialogWithCompletionBlock:(DoorbellCompletionBlock)completion
{
    self.block = completion;
    UIWindow *currentWindow = [UIApplication sharedApplication].keyWindow;
    self.dialog = [[DoorbellDialog alloc] initWithFrame:currentWindow.frame];
    self.dialog.delegate = self;
    self.dialog.showEmail = self.showEmail;
    self.dialog.email = self.email;
    self.dialog.showPoweredBy = self.showPoweredBy;
    [currentWindow addSubview:self.dialog];
}

#pragma mark - Selectors

- (void)fieldError:(NSString*)validationError
{
    if ([validationError hasPrefix:@"Your email address is required"]) {
        [self.dialog highlightEmailEmpty];
    }
    else if ([validationError hasPrefix:@"Invalid email address"]) {
        [self.dialog highlightEmailInvalid];
    }
    else {
        [self.dialog highlightMessageEmpty];
    }

    self.dialog.sending = NO;
}

- (void)finish
{
    [self.dialog removeFromSuperview];
    self.block(nil, NO);
}

#pragma mark - Dialog delegate

- (void)dialogDidCancel:(DoorbellDialog*)dialog
{
    [dialog removeFromSuperview];
    self.block(nil, YES);
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

    NSString *query = [NSString stringWithFormat:EndpointTemplate, self.appID, @"open", self.apiKey];
    NSURL *openURL = [NSURL URLWithString:query];
    NSMutableURLRequest *openRequest = [NSMutableURLRequest requestWithURL:openURL];
    [openRequest setHTTPMethod:@"POST"];


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

- (void)sendSubmit:(NSString*)message email:(NSString*)email
{
    NSString *query = [NSString stringWithFormat:EndpointTemplate, self.appID, @"submit", self.apiKey];
    NSURL *submitURL = [NSURL URLWithString:query];

    NSMutableDictionary *submitData = [[NSMutableDictionary alloc] init];
    [submitData setValue:message forKey:@"message"];
    [submitData setValue:email forKey:@"email"];
    [submitData setValue:self.properties forKey:@"properties"];
    [submitData setValue:self.name forKey:@"name"];

    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:submitData
                                                       options:(NSJSONWritingOptions)0
                                                         error:&error];

    if (! jsonData) {
        NSLog(@"JSON Encoding error: %@", error.localizedDescription);
        return;
    }

    NSMutableURLRequest *submitRequest = [NSMutableURLRequest requestWithURL:submitURL];
    [submitRequest setHTTPMethod:@"POST"];

    NSURLSessionUploadTask *submitTask = [_session uploadTaskWithRequest:submitRequest
                                                               fromData:jsonData
                                                      completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                                           if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                                                               NSHTTPURLResponse *httpResp = (id)response;
                                                               NSString *content = [NSString stringWithUTF8String:data.bytes];
                                                               NSLog(@"%d:%@", (int)httpResp.statusCode, content);
                                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                                   [self manageSubmitResponse:httpResp content:content];
                                                               });
                                                           }
                                                       }];
    [submitTask resume];

    if (self.images.count > 0) {
        [self uploadImages];
    }
}

- (void)uploadImages {
    NSURLSessionConfiguration *conf = [[NSURLSessionConfiguration alloc] init];
    [conf setHTTPAdditionalHeaders:@{@"Accept"        : @"application/json",
                                     @"Content-Type"  : [NSString stringWithFormat:@"multipart/form-data; boundary=%@", self.imageBoundary]
                                     }];
    NSURLSession *uploadSession = [NSURLSession sessionWithConfiguration:conf];

    NSString *query = [NSString stringWithFormat:EndpointTemplate, self.appID, @"submit", self.apiKey];
    NSURL *uploadURL = [NSURL URLWithString:query];

    NSMutableURLRequest *uploadRequest = [[NSMutableURLRequest alloc] initWithURL:uploadURL];
    uploadRequest.HTTPMethod = @"POST";
    //uploadRequest.HTTPBody = [self createImageUploadBodyData];

    NSURLSessionUploadTask *uploadTask = [uploadSession uploadTaskWithRequest:uploadRequest
                                                                     fromData:[self createImageUploadBodyData]
                                                            completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                                                if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                                                                    NSHTTPURLResponse *httpResp = (id)response;
                                                                    NSString *content = [NSString stringWithUTF8String:data.bytes];
                                                                    NSLog(@"%d:%@", (int)httpResp.statusCode, content);
//                                                                    dispatch_async(dispatch_get_main_queue(), ^{
//                                                                        [self manageSubmitResponse:httpResp content:content];
//                                                                    });
                                                                }
                                                            }];
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

- (void)manageSubmitResponse:(NSHTTPURLResponse*)response content:(NSString*)content
{
    switch (response.statusCode) {
        case 201:
            [self finish];
            break;
        case 400:
            [self fieldError:content];
            break;

        default:
            [self.dialog removeFromSuperview];
            self.block([NSError errorWithDomain:@"doorbell.io" code:3 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"%d: HTTP unexpected\n%@", (int)response.statusCode, content]}] , YES);
            break;
    }
}
@end
