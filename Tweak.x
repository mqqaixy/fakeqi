#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

// 默认坐标
static double customLat = 39.9042;
static double customLng = 116.4074;

// --- 虚拟定位 Hook ---
%hook CLLocation
- (CLLocationCoordinate2D)coordinate {
    CLLocationCoordinate2D coords = %orig;
    coords.latitude = customLat;
    coords.longitude = customLng;
    return coords;
}
%end

// --- 弹窗 UI 逻辑 ---
@interface FakeLocManager : NSObject
+ (void)presentSettings;
@end

@implementation FakeLocManager
+ (void)presentSettings {
    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (rootVC.presentedViewController) {
        rootVC = rootVC.presentedViewController;
    }

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"📍 虚拟定位" 
                                                                   message:@"输入格式: 纬度,经度" 
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) {
        tf.placeholder = [NSString stringWithFormat:@"当前: %.4f, %.4f", customLat, customLng];
        tf.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    }];

    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *input = alert.textFields.firstObject.text;
        NSArray *parts = [input componentsSeparatedByString:@","];
        if (parts.count == 2) {
            customLat = [parts[0] doubleValue];
            customLng = [parts[1] doubleValue];
        }
    }]];

    [rootVC presentViewController:alert animated:YES completion:nil];
}
@end

// --- 注入长按手势 ---
%hook UIWindow
- (void)becomeKeyWindow {
    %orig;
    // 检查是否已经添加过手势，防止重复
    BOOL hasGest = NO;
    for (UIGestureRecognizer *g in self.gestureRecognizers) {
        if ([g isKindOfClass:[UILongPressGestureRecognizer class]] && g.numberOfTouchesRequired == 2) {
            hasGest = YES;
            break;
        }
    }
    
    if (!hasGest) {
        UILongPressGestureRecognizer *twoFingerLP = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleFakeLoc:)];
        twoFingerLP.numberOfTouchesRequired = 2;
        twoFingerLP.minimumPressDuration = 0.8;
        [self addGestureRecognizer:twoFingerLP];
    }
}

%new
- (void)handleFakeLoc:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        [FakeLocManager presentSettings];
    }
}
%end
