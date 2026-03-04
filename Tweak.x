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

@interface FakeLocUI : NSObject
@end

@implementation FakeLocUI
+ (void)show {
    UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (vc.presentedViewController) vc = vc.presentedViewController;
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"定位修改" message:nil preferredStyle:1];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) {
        tf.placeholder = @"纬度,经度";
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:0 handler:^(id act) {
        NSString *txt = alert.textFields.firstObject.text;
        NSArray *p = [txt componentsSeparatedByString:@","];
        if (p.count == 2) {
            customLat = [p[0] doubleValue];
            customLng = [p[1] doubleValue];
        }
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:1 handler:nil]];
    [vc presentViewController:alert animated:YES completion:nil];
}
@end

%hook UIWindow
- (void)becomeKeyWindow {
    %orig;
    UILongPressGestureRecognizer *g = [[UILongPressGestureRecognizer alloc] initWithTarget:[FakeLocUI class] action:@selector(show)];
    g.numberOfTouchesRequired = 2;
    [self addGestureRecognizer:g];
}
%end
