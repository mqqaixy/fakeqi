#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

// 默认坐标（北京）
static double customLat = 39.9042;
static double customLng = 116.4074;

// --- 拦截系统定位 ---
%hook CLLocation
- (CLLocationCoordinate2D)coordinate {
    CLLocationCoordinate2D coords = %orig;
    coords.latitude = customLat;
    coords.longitude = customLng;
    return coords;
}
%end

// --- 弹窗交互逻辑 ---
@interface LocationManagerUI : NSObject
+ (void)showSettings;
@end

@implementation LocationManagerUI
+ (void)showSettings {
    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (rootVC.presentedViewController) rootVC = rootVC.presentedViewController;

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"📍 虚拟定位控制台" 
                                                                   message:@"请输入目标坐标 (纬度,经度)" 
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) {
        tf.placeholder = [NSString __stringWithFormat:@"当前: %.4f, %.4f", customLat, customLng];
        tf.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    }];

    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"保存并应用" style:UIAlertActionStyleDefault handler:^(id action) {
        NSString *input = alert.textFields.firstObject.text;
        if (input.length > 0) {
            NSArray *parts = [input componentsSeparatedByString:@","];
            if (parts.count == 2) {
                customLat = [parts[0] doubleValue];
                customLng = [parts[1] doubleValue];
            }
        }
    }];

    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:ok];
    [rootVC presentViewController:alert animated:YES completion:nil];
}
@end

// --- 注入双指长按手势 ---
%hook UIWindow
- (void)becomeKeyWindow {
    %orig;
    // 添加两指长按手势（长按0.8秒触发）
    UILongPressGestureRecognizer *gest = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleFakeLocGesture:)];
    gest.numberOfTouchesRequired = 2; 
    gest.minimumPressDuration = 0.8;
    [self addGestureRecognizer:gest];
}

%new
- (void)handleFakeLocGesture:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        [LocationManagerUI showSettings];
    }
}
%end
