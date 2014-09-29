# Doorbell iOS SDK

The Doorbell iOS SDK.

## Usage

At the top of your class, import the Doorbell header file:
```objc
#import "Doorbell.h"
```

Then when you want to show the dialog:

```objc
NSString *appId = @"123";
NSString *appKey = @"xxxxxxxxxxxxxxxxxx";

Doorbell *feedback = [Doorbell doorbellWithApiKey:appKey appId:appId];
[feedback showFeedbackDialogInViewController:self completion:^(NSError *error, BOOL isCancelled) {
    if (error) {
        NSLog(@"%@", error.localizedDescription);
    }
}];
```

To pre-populate the email address (if the user is logged in for example):

```objc
NSString *appId = @"123";
NSString *appKey = @"xxxxxxxxxxxxxxxxxx";

Doorbell *feedback = [Doorbell doorbellWithApiKey:appKey appId:appId];
feedback.showEmail = NO;
feedback.email = @"email@example.com";
[feedback showFeedbackDialogInViewController:self completion:^(NSError *error, BOOL isCancelled) {
    if (error) {
        NSLog(@"%@", error.localizedDescription);
    }
}];
```
