#import <UIKit/UIKit.h>

@class CameraViewController;
@protocol CameraViewControllerDelegate <NSObject>
-(void)btleDiscoverDeviceWithSerial:(NSString *)serial;
@end

@interface CameraViewController : UIViewController
{
}

@property (nonatomic, weak) id <CameraViewControllerDelegate> delegate;
@end
