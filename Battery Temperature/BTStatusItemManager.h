//
//  BTStatusItemManager.h
//  Battery Temperature
//
//  Created by Colin Campbell on 8/24/15.
//
//

#import <Foundation/Foundation.h>

@interface BTStatusItemManager : NSObject {
    BOOL _highTempEnabled;
    BOOL _lowTempEnabled;
}

@property(nonatomic, assign) BOOL highTempEnabled;
@property(nonatomic, assign) BOOL lowTempEnabled;

+ (BTStatusItemManager *)sharedManager;
- (void)updateTemperature:(NSNumber *)temperature;


@end
