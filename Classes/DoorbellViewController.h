//
//  DoorbellViewController.h
//  DoorbelliOS
//
//  Created by Nicolas Peariso on 1/28/16.
//  Copyright © 2016 Doorbell. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DoorbellViewController : UIViewController<UITextViewDelegate, UITextFieldDelegate>

@property (readonly, nonatomic) NSString *bodyText;
@property (strong, nonatomic) NSString *email;
@property (assign, nonatomic)   BOOL showEmail;
@property (assign, nonatomic)   BOOL showPoweredBy;
@property (assign, nonatomic)   BOOL sending;

@property (strong, nonatomic) id delegate;

- (void)highlightEmailEmpty;
- (void)highlightEmailInvalid;
- (void)highlightMessageEmpty;

@end

@protocol DoorbellDialogDelegate <NSObject>

- (void)dialogDidCancel:(DoorbellViewController*)dialog;
- (void)dialogDidSend:(DoorbellViewController*)dialog;

@end