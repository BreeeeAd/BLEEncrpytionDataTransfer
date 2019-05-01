//
//  WMLShortRangeManager.h
//  WMLBeaconCollection
//
//  Created by sy2036 on 2016-12-05.
//  Copyright © 2016 WineMocol. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class WMLShortRangeManager;

@protocol WMLShortRangeManagerDelegate <NSObject>

@optional

- (void)shortRangeManager:(WMLShortRangeManager *)shortRangeManager didReceiveData:(NSString *)receivedData;

@end

@interface WMLShortRangeManager : NSObject

@property (strong, nonatomic) id<WMLShortRangeManagerDelegate> delegate;

- (void)scan;
- (void)refresh;

- (BOOL)sendMessage:(NSString *)sendMessage;

@end
