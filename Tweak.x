#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

static double customLat = 39.9042;
static double customLng = 116.4074;

%hook CLLocation
- (CLLocationCoordinate2D)coordinate {
    CLLocationCoordinate2D coords = %orig;
    coords.latitude = customLat;
    coords.longitude = customLng;
    return coords;
}
%end

%hook UIWindow
- (void)becomeKeyWindow {
    %orig;
    UILongPressGestureRecognizer *g = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleFake:)];
    g.numberOfTouchesRequired = 2; // 两指长按
    [self addGestureRecognizer:g];
}

%new
- (void)handleFake:(UILongPressGestureRecognizer *)s {
    if (s.state == UIGestureRecognizerStateBegan) {
        UIViewController *root = [UIApplication sharedApplication].keyWindow.rootViewController;
        while (root.presentedViewController) root = root.presentedViewController;
        UIAlertController *a = [UIAlertController alertControllerWithTitle:@"坐标设置" message:@"格式: 纬度,经度" preferredStyle:1];
        [a addTextFieldWithConfigurationHandler:nil];
        [a addAction:[UIAlertAction actionWithTitle:@"确定" style:0 handler:^(id act) {
            NSArray *p = [a.textFields.firstObject.text componentsSeparatedByString:@","];
            if (p.count == 2) {
                customLat = [p[0] doubleValue];
                customLng = [p[1] doubleValue];
            }
        }]];
        [a addAction:[UIAlertAction actionWithTitle:@"取消" style:1 handler:nil]];
        [root presentViewController:a animated:YES completion:nil];
    }
}
%end
