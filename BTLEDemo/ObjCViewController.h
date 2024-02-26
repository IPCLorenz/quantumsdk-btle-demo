//
//  ObjCViewController.h
//  BTLEDemo
//
//  Created by Lorenz Cunanan on 6/1/22.
//

#import <UIKit/UIKit.h>
#import <QuantumSDK/QuantumSDK.h>
#import "CameraViewController.h"

@interface ObjCViewController : UIViewController <IPCDTDeviceDelegate, CameraViewControllerDelegate> {
    CameraViewController *cameraVC;
    
    IPCDTDevices *dtdev;
    
    CBPeripheral *connectedDevice;
    
    __weak IBOutlet UITextView *connectionTextView;
    __weak IBOutlet UIButton *btleDisconnectButton;
    __weak IBOutlet UILabel *btleLabel;
    __weak IBOutlet UIActivityIndicatorView *spinner;
    
}

@property (strong,nonatomic) NSArray<CBPeripheral *> *btleDevices;

@end
