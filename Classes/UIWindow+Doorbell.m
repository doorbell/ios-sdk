#import "UIWindow+Doorbell.h"

@implementation UIWindow (Doorbell)

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (event.type == UIEventTypeMotion && event.subtype == UIEventSubtypeMotionShake) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UIDoorbellWindowDidShake" object:self];
        return;
    }
    
    [[self nextResponder] motionEnded:motion withEvent:event];
}

@end
