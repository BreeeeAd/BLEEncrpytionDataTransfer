//
//  WMLShortRangeManager.m
//  WMLBeaconCollection
//
//  Created by sy2036 on 2016-12-05.
//  Copyright © 2016 WineMocol. All rights reserved.
//

#import "WMLShortRangeManager.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "WMLGlobalDefine.h"
#import "UIAlertController+NoViewDisplay.h"
#import "NSData+AES256.h"

@interface WMLShortRangeManager() <CBCentralManagerDelegate, CBPeripheralManagerDelegate, CBPeripheralDelegate>

@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) CBPeripheralManager *peripheralManager;
@property (strong, nonatomic) CBPeripheral *connectedPeripheral;
@property (strong, nonatomic) NSMutableArray *connectedPeripherals;
@property (strong, nonatomic) NSMutableArray *centrals; //keep registered central devices

@property (strong, nonatomic) NSMutableData *receivedData;

//Configurations for sending data.
@property NSUInteger offset;
@property NSUInteger maximumLength;
@property NSUInteger sendDataLength;
@property NSData *updateData;
@property CBMutableCharacteristic *characteristic;
@property NSArray *sendingCentrals;

//Configuration for receiving data.
@property (strong, nonatomic) NSString *currentReceivingPeripheral;

@end

@implementation WMLShortRangeManager

- (void)getUUID {
    NSString *uuidStr = [[NSUUID UUID] UUIDString];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults objectForKey:@"DEVICE_UUID"] == nil) {
        [userDefaults setObject:uuidStr forKey:@"DEVICE_UUID"];
        [userDefaults synchronize];
    }
    
}

- (id)init {
    self = [super init];
    if (self) {
        [self getUUID];
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
        
        _centrals = [[NSMutableArray alloc] init];
        _connectedPeripherals = [[NSMutableArray alloc] init];
        
        _currentReceivingPeripheral = [[NSString alloc] init];
        
        _receivedData = [[NSMutableData alloc] init];
        
    }
    return self;
}

- (void)startedBroadcast {
    CBMutableService *service = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:TRANSFER_UUID] primary:YES];
    
    //CBMutableCharacteristic *characteristic
    _characteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:TRANSFER_UUID] properties:(CBCharacteristicPropertyNotify|CBCharacteristicPropertyRead|CBCharacteristicPropertyWrite) value:nil permissions:(CBAttributePermissionsWriteable|CBAttributePermissionsReadable)];
    
    service.characteristics = @[_characteristic];
    
    [_peripheralManager addService:service];
    
    NSString *deviceName = [[UIDevice currentDevice] name];
    deviceName = [deviceName stringByAppendingString:[[NSUUID UUID] UUIDString]];
    
    [_peripheralManager startAdvertising:@{ CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:TRANSFER_UUID]], CBAdvertisementDataLocalNameKey:deviceName}];
}

- (void)refresh {
    for (CBPeripheral *peripheral in _connectedPeripherals) {
        if (peripheral.state != CBPeripheralStateConnected) {
            [_connectedPeripherals removeObject:peripheral];
        } else {
            if ([[peripheral services] count] >0) {
                CBService *service = [[peripheral services] objectAtIndex:0];
                if ([[service characteristics] count] > 0) {
                    CBCharacteristic *ch = [[service characteristics] objectAtIndex:0];
                    [peripheral readValueForCharacteristic:ch];
                }
            }
        }
    }
    [self scan];
}

- (void)scan {
    for (CBPeripheral *peripheral in _connectedPeripherals) {
        if (peripheral.state != CBPeripheralStateConnected) {
            [_connectedPeripherals removeObject:peripheral];
            NSString *title;
            title = @"Warning";
            NSString *message = @"Please turn on the bluetooth, the app doesn't cost much power.";
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:(UIAlertControllerStyleAlert)];
            UIAlertAction *setAction = [UIAlertAction actionWithTitle:@"Settings" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction *action) {
                NSLog(@"Setting");
            }];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:(UIAlertActionStyleCancel) handler:^(UIAlertAction *action) {
                NSLog(@"Cancel");
            }];
            [alertController addAction:setAction];
            [alertController addAction:cancelAction];
            
            [alertController show];
        }
    }
    
    if (_centralManager.state != CBManagerStatePoweredOn) {
        return;
    }
    
    NSDictionary *scanOptions = @{CBCentralManagerScanOptionAllowDuplicatesKey:@(NO)};
    NSArray *services = @[[CBUUID UUIDWithString:TRANSFER_UUID]];
    [_centralManager scanForPeripheralsWithServices:services options:scanOptions];
}

#pragma mark - CBCentralManagerDelegate
/*Initialize centralmanager, and scan peripheral devices*/
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    if (central.state != CBManagerStatePoweredOn) {
        return;
    }
    [self scan];
}

/*If found peripheral devices, connect */
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {

    
    for (CBPeripheral *connectedPeripheral in _connectedPeripherals) {
        if ([peripheral.name isEqualToString:connectedPeripheral.name]) {
            NSLog(@"%@ is already connected", peripheral.name);
            return;
        }
    }
    [_connectedPeripherals addObject:peripheral];
    _connectedPeripheral = peripheral;
    [central connectPeripheral:peripheral options:nil];
}

/*If connect to device, stop scaning and begin to scan wanted services */
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"Connected device: %@", peripheral.name);
    peripheral.delegate = self;
    [peripheral discoverServices:@[[CBUUID UUIDWithString:TRANSFER_UUID]]];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    [_connectedPeripherals removeObject:peripheral];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Failed to connect to peripheral: %@", [peripheral name]);
    [_connectedPeripherals removeObject:peripheral];
}

#pragma mark - CBPeripheralDelegate
/*If wanted service discovered, begin to scan wanted characteristic*/
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (error) {
        NSLog(@"Discover service happened error: %@", [error localizedDescription]);
        return;
    }
    for (CBService *service in [peripheral services]) {
        if ([[[service UUID] UUIDString] isEqualToString:TRANSFER_UUID]) {
            [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:TRANSFER_UUID]] forService:service];
        }
    }
}

/*If wanted characteristic founded, register and read value*/
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error) {
        NSLog(@"Discover characteristic happened error: %@", [error localizedDescription]);
        return;
    }
    
    NSLog(@"Discovered characteristic in %@", peripheral.name);
    for (CBCharacteristic *characteristic in [service characteristics]) {
        NSLog(@"I get the characteristic that we want.");
        NSLog(@"%@", characteristic.UUID.UUIDString);
        
        if ([[[characteristic UUID] UUIDString] isEqualToString:TRANSFER_UUID]) {
            NSLog(@"I get the characteristic that we want.");
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            [peripheral readValueForCharacteristic:characteristic];
            break;
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if (error) {
        NSLog(@"Error changing notification state: %@", error.localizedDescription);
    }
    // Notification has started
    if (characteristic.isNotifying) {
        NSLog(@"Notification began on %@", characteristic);
    }
}

/*Receiving data from peripheral devices*/
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error)
        return;
    if ([_currentReceivingPeripheral isEqualToString:@""])
        _currentReceivingPeripheral = peripheral.name;
    if (![_currentReceivingPeripheral isEqualToString:[peripheral name]])
        return;
    NSData *tmpData = [characteristic value];
    NSString *tmpString = [[NSString alloc] initWithData:tmpData encoding:NSUTF8StringEncoding];
    if (![tmpString isEqualToString:@"ZQQ"]) {
        [_receivedData appendData:tmpData];
        return;
    }

    _currentReceivingPeripheral = @"";
    NSData *messageData = [NSData dataWithData:_receivedData];
    NSString *msgDatastr = [[NSString alloc] initWithData:messageData encoding:NSUTF8StringEncoding];
    if ([_delegate respondsToSelector:@selector(shortRangeManager:didReceiveData:)]) {
        [_delegate shortRangeManager:self didReceiveData:msgDatastr];
    }
    
    //  Initial the receive data after obtaining data.
    [_receivedData setLength:0];
    _receivedData = nil;
    _receivedData = [[NSMutableData alloc] init];
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error)
        NSLog(@"Error happend, %@. Error code: %ld", [error localizedDescription], (long)[error code]);
}

#pragma mark - CBPeripheralManagerDelegate

/*Start broadcasting as peripheral device*/
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    if (peripheral.state != CBManagerStatePoweredOn)
        return;
    [self startedBroadcast];
    NSLog(@"Peripheral updated");
}

/*Resend data if failed in previous action*/
- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral {
    [self sendData];
}

#pragma mark -- Message Helpers

- (BOOL)sendMessage:(NSString *)sendMessage {
    if (sendMessage == nil) {
        NSLog(@"Parse message failed");
        return NO;
    }
    NSData *msgData = [sendMessage dataUsingEncoding:NSUTF8StringEncoding];
    
    NSLog(@"The data length is: %lu", (unsigned long)[msgData length]);
    _updateData = msgData;
    _offset = 0;
    _sendDataLength = [msgData length];
    _maximumLength = 20;
    _sendingCentrals = nil;
    
    [self sendData];
    return YES;
}

/* Internal method */
- (void)sendData {
    static BOOL sendingZQQ = NO;
    if (sendingZQQ) {
        NSLog(@"Sending ZQQ");
        BOOL didSend = [_peripheralManager updateValue:[@"ZQQ" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:_characteristic onSubscribedCentrals:nil];
        if (didSend) {
            NSLog(@"Sent ZQQ successfully");
            sendingZQQ = NO;
        }
        return;
    }
    if (_offset >= _sendDataLength) {
        _offset = 0;
        return;
    }
    BOOL didSend = YES;
    while (didSend) {
        NSUInteger chunkSize = (_sendDataLength - _offset) > _maximumLength ? _maximumLength : (_sendDataLength - _offset);
        NSData *chunk = [NSData dataWithBytes:((char *)[_updateData bytes] + _offset) length:chunkSize];
        
        if (chunk == nil)
            return;
        
        didSend = [_peripheralManager updateValue:chunk forCharacteristic:_characteristic onSubscribedCentrals:_sendingCentrals];
        if (!didSend) {
            NSLog(@"Oh, it failed to send the data");
            return;
        } else
            NSLog(@"Send successfully");
        
        _offset = _offset + chunkSize;
        if (_offset >= _sendDataLength) {
            sendingZQQ = YES;
            BOOL ZQQSent = [_peripheralManager updateValue:[@"ZQQ" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:_characteristic onSubscribedCentrals:nil];
            if (ZQQSent) {
                NSLog(@"Sent ZQQ successfully");
                didSend = NO;
                sendingZQQ = NO;
                _offset = 0;
                _sendDataLength = 0;
            } else
                NSLog(@"Sent ZQQ Failed");
        }
    }
}

@end
