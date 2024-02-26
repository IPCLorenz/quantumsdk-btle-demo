//
//  ObjCViewController.m
//  BTLEDemo
//
//  Created by Lorenz Cunanan on 6/1/22.
//

#import "ObjCViewController.h"

@interface ObjCViewController ()

@end

@implementation ObjCViewController

// MARK: - VIEW DELEGATES

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [spinner setHidden:TRUE];
    
    dtdev = [IPCDTDevices sharedDevice];
    [dtdev addDelegate:self];
    
    [dtdev connect];
    
    // SCAN TO PAIR
    cameraVC = [[CameraViewController alloc] init];
    cameraVC.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated {
    [dtdev addDelegate:self];
    
    [self connectionState:dtdev.connstate];
}

- (void)viewWillDisappear:(BOOL)animated {
    [dtdev removeDelegate:self];
}

// MARK: - IPC DELEGATES
- (void)connectionState:(int)state {
    NSString *status;
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateStyle:NSDateFormatterLongStyle];
    
    status = [NSString stringWithFormat:@"SDK: ver %d.%d (%@)\n",dtdev.sdkVersion/100,dtdev.sdkVersion%100,[dateFormat stringFromDate:dtdev.sdkBuildDate]];
    
    if(state == CONN_CONNECTED)
    {
        status = [status stringByAppendingFormat:@"\n%@ %@ connected\nFirmware revision: %@\nHardware revision: %@\nSerial number: %@",dtdev.deviceName,dtdev.deviceModel,dtdev.firmwareRevision,dtdev.hardwareRevision,dtdev.serialNumber];
        
        connectionTextView.text = status;
    }
    else{
        
        status = [status stringByAppendingFormat:@"\nNo device connected"];
        
        connectionTextView.text = status;
    }
    
    NSString *btleDevice = [[NSUserDefaults standardUserDefaults] stringForKey:@"selectedBTLEDevice"];
    
    if (![[NSUserDefaults standardUserDefaults] stringForKey:@"selectedBTLEUUID"]) {
        btleDisconnectButton.hidden = true;
        btleLabel.text = @"";
    } else {
        btleDisconnectButton.hidden = false;
        btleLabel.text = [NSString stringWithFormat:@"Previous device: %@", btleDevice];
    }
}

- (void)barcodeData:(NSString *)barcode type:(int)type {
    [self displayAction:@"Barcode scanned" message:[NSString stringWithFormat:@"%@ (%lu): %@", [dtdev barcodeType2Text:type], barcode.length, barcode]];
}

// MARK: - BTLE HELPERS
-(void)displayAction:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *actionOk = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^ (UIAlertAction * _Nonnull action) {

        NSLog(@"%@: %@", title, message);
    }];

    [alert addAction:actionOk];
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)btleConnect:(CBPeripheral *)connectedDevice {
    NSLog(@"Connected Device: %@", connectedDevice);
    
    spinner.hidden = false;
    [spinner startAnimating];
    
    if([dtdev.btleConnectedDevices containsObject:connectedDevice])
    {
        [dtdev btleDisconnect:connectedDevice error:nil];
        [self displayAction:@"Device Disconnected" message:connectedDevice.name];
    }else
    {
        NSError *error=nil;
        
        if([dtdev btleConnectToDevice:connectedDevice error:&error])
        {
            [[NSUserDefaults standardUserDefaults] setValue:connectedDevice.name forKey:@"selectedBTLEDevice"];
            [[NSUserDefaults standardUserDefaults] setValue:connectedDevice.identifier.UUIDString forKey:@"selectedBTLEUUID"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
        }else
        {
            [self displayAction:@"BluetoothLE Error" message:error.localizedDescription];
        }
    }
    
    self->spinner.hidden = true;
    [self->spinner stopAnimating];
}

-(void)btleDiscover {
    
    NSLog(@"BTLE DIscover...");
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error=nil;
        
        self.btleDevices=[self->dtdev btleDiscoverSupportedDevices:BLUETOOTH_FILTER_ALL stopOnFound:false error:&error];
        NSLog(@"BTLE DIscover...finished!");

        dispatch_async(dispatch_get_main_queue(), ^{
            if(!self.btleDevices)
            {
                [self displayAction:@"Bluetooth Error" message:error.localizedDescription];
            }
            
            bool isBluetooth = NO;
            
            NSArray *connected = [self->dtdev getConnectedDevicesInfo:nil];
            
            for (DTDeviceInfo *info in connected)
            {
                NSLog(info.connectionType == CONNECTION_BLUETOOTH ? @"DEVICE CONNECTION TYPE: YES" : @"DEVICE CONNECTION TYPE: NO");
                
                NSLog(@"\nDevice Name:%@ \nConnection Type: %d\nDevice Type: %d", info.name, info.connectionType, info.deviceType);
                
                // conn type, bt = 2
                
                // check for printer instead of conn type
                if (info.deviceType == DEVICE_TYPE_PRINTER)
                    isBluetooth = YES;
            }
                
                if (self->dtdev.btleConnectedDevices.count == 0 && !isBluetooth){
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"BTLE Devices Found" message:@"Choose device from list" preferredStyle:UIAlertControllerStyleAlert];

                    for (int i=0;i<self->_btleDevices.count;i++){
                        UIAlertAction *action = [UIAlertAction actionWithTitle:self.btleDevices[i].name style:UIAlertActionStyleDefault handler:^ (UIAlertAction * _Nonnull action) {

                            NSLog(@"Connecting to: %@", self.btleDevices[i].name);

                            self->connectedDevice = self.btleDevices[i];
                            
                            [self btleConnect:self->connectedDevice];
                        }];
                        [alert addAction:action];
                    }

                    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"#### CANCEL ####" style:UIAlertActionStyleCancel handler:^ (UIAlertAction * _Nonnull action){
                        NSLog(@"Cancelled");
                    }];

                    [alert addAction:cancel];
                    [self presentViewController:alert animated:YES completion:nil];
                    
                    
                }
                else{
                    [self displayAction:@"Please disconnect from previous device first" message:@""];
                }
            
            self->spinner.hidden = true;
            [self->spinner stopAnimating];
        });
    });
}

// MARK: - SCAN TO PAIR
typedef void (^BTLEDiscoverCompletionBlock)(void);

-(void)btleDiscoverDeviceWithSerial:(NSString *)serial {
    //is it already discovered?
    for (CBPeripheral *device in self.btleDevices) {
        if([device.name hasSuffix:serial])
        {
            [self btleConnectToDevice:device];
            return;
        }
    }

    [self btleDiscover:^(void)
    {
        for (CBPeripheral *device in self.btleDevices) {
            if([device.name hasSuffix:serial])
            {
                [self btleConnectToDevice:device];
                break;
            }
        }
    }];
}

-(void)btleDiscover:(BTLEDiscoverCompletionBlock)completion {
    NSLog(@"BTLE DIscover...");
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error=nil;

        self.btleDevices=[self->dtdev btleDiscoverSupportedDevices:BLUETOOTH_FILTER_ALL stopOnFound:false error:&error];
        NSLog(@"BTLE DIscover...finished!");

        dispatch_async(dispatch_get_main_queue(), ^{
            if(!self.btleDevices)
            {
                NSLog(NSLocalizedString(@"Bluetooth Error",nil));
            }else{
                if(completion)
                    completion();
            }
        });
    });

}

-(void)btleConnectToDevice:(CBPeripheral *)selectedDevice {
    [dtdev btleDiscoverStop];
    
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    
    if([dtdev.btleConnectedDevices containsObject:selectedDevice])
    {
        [dtdev btleDisconnect:selectedDevice error:nil];
    }else
    {
        NSError *error=nil;
        if([dtdev btleConnectToDevice:selectedDevice error:&error])
        {
            [[NSUserDefaults standardUserDefaults] setValue:selectedDevice.name forKey:@"selectedBTLEDevice"];
            [[NSUserDefaults standardUserDefaults] setValue:selectedDevice.identifier.UUIDString forKey:@"selectedBTLEUUID"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }else
        {
            NSLog(NSLocalizedString(@"BluetoothLE Error",nil));
        }
    }
}

// MARK: - ACTIONS
- (IBAction)actionScanConnect:(id)sender {
    // SCAN TO PAIR
    if(dtdev.btleConnectedDevices.count > 0)
        return;
    
//    NSString * storyboardName = @"Main";
//    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle: nil];
//    UIViewController * vc = [storyboard instantiateViewControllerWithIdentifier:@"cameraVC"];
//    [self presentViewController:vc animated:YES completion:nil];
    
    
    [self.view addSubview:cameraVC.view];
}

- (IBAction)actionDiscover:(id)sender {
    [self btleDiscover];
    
    spinner.hidden = false;
    [spinner startAnimating];
}

- (IBAction)actionDisconnect:(id)sender {
    NSError *error = nil;
    
    NSString *btleUUIDStr=[NSUserDefaults.standardUserDefaults stringForKey:@"selectedBTLEUUID"];
    NSUUID *uuid = nil;
    if(btleUUIDStr!=nil)
        uuid = [[NSUUID alloc] initWithUUIDString:btleUUIDStr];
        
    if (uuid != nil) {
        connectedDevice = [dtdev btleGetKnownDeviceWithUUID:uuid error:&error];
            
        if (uuid != nil && dtdev.btleConnectedDevices.count != 0) {
            [dtdev btleDisconnect:connectedDevice error:&error];
            [self displayAction:@"BTLE Device Disconnected" message:connectedDevice.name];
        } else {
            [self displayAction:@"No BTLE Devices Connected" message:@""];
        }
    }
}

- (IBAction)actionReconnect:(id)sender {
    NSError *error = nil;
    NSString *btleUUIDStr=[NSUserDefaults.standardUserDefaults stringForKey:@"selectedBTLEUUID"];
    NSUUID *uuid = nil;
    if(btleUUIDStr!=nil)
        uuid = [[NSUUID alloc] initWithUUIDString:btleUUIDStr];

    if(uuid!=nil && dtdev.btleConnectedDevices.count!=0 && [dtdev.btleConnectedDevices[0].identifier.UUIDString isEqualToString:btleUUIDStr])
    {//we are already connected, disconnect
        [dtdev btleDisconnect:dtdev.btleConnectedDevices[0] error:nil];
    }else
    {
        if(uuid!=nil && dtdev.btleConnectedDevices.count==0)
        {//idea here - try to find paired device, if not - perform discovery, get the device, connect to it
            CBPeripheral *selectedDevice = [dtdev btleGetKnownDeviceWithUUID:uuid error:&error]; //try with paired first

            if(selectedDevice==nil)//try to discover if none found
            {
                [self btleDiscover];
                for(int i=0;i<self.btleDevices.count;i++)
                {
                    if([self.btleDevices[i].identifier isEqual:uuid])
                    {
                        selectedDevice = self.btleDevices[i];
                        break;
                    }
                }
            }
            if(selectedDevice!=nil)
                [self btleConnect:selectedDevice];
        }
    }
}

@end
