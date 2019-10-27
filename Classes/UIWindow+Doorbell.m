#import "UIWindow+Doorbell.h"

@implementation UIWindow (Doorbell)

- (void)DB_motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    [self DB_motionEnded:motion withEvent:event];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UIDoorbellWindowDidShake" object:event];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {}

@end
