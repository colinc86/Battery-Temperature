//
//  Headers.h
//  Battery Temperature
//
//  Created by Colin Campbell on 8/26/15.
//
//

typedef struct {
    char itemIsEnabled[25];
    char timeString[64];
    int gsmSignalStrengthRaw;
    int gsmSignalStrengthBars;
    char serviceString[100];
    char serviceCrossfadeString[100];
    char serviceImages[2][100];
    char operatorDirectory[1024];
    unsigned int serviceContentType;
    int wifiSignalStrengthRaw;
    int wifiSignalStrengthBars;
    unsigned int dataNetworkType;
    int batteryCapacity;
    unsigned int batteryState;
    char batteryDetailString[150];
    int bluetoothBatteryCapacity;
    int thermalColor;
    unsigned int thermalSunlightMode:1;
    unsigned int slowActivity:1;
    unsigned int syncActivity:1;
    char activityDisplayId[256];
    unsigned int bluetoothConnected:1;
    unsigned int displayRawGSMSignal:1;
    unsigned int displayRawWifiSignal:1;
    unsigned int locationIconType:1;
    unsigned int quietModeInactive:1;
    unsigned int tetheringConnectionCount;
} CDStruct_4ec3be00;

@interface UIStatusBar ()
- (void)setShowsOnlyCenterItems:(BOOL)arg1;
- (UIView *)snapshotViewAfterScreenUpdates:(BOOL)arg1;
@end

@interface UIStatusBarServer : NSObject
+ (CDStruct_4ec3be00 *)getStatusBarData;
+ (void)postStatusBarData:(CDStruct_4ec3be00 *)arg1 withActions:(int)arg2;
@end

@interface SBStatusBarStateAggregator
+ (id)sharedInstance;
- (BOOL)_setItem:(int)arg1 enabled:(BOOL)arg2;
- (void)_updateBatteryItems;
- (void)updateStatusBarItem:(int)arg1;
@end

@interface _UILegibilityImageSet : NSObject {
    UIImage *_image;
    UIImage *_shadowImage;
}
@property (nonatomic, retain) UIImage *image;
@end

@interface UIStatusBarItemView : UIView {
    BOOL _allowsUpdates;
}
@property (nonatomic) BOOL allowsUpdates;
- (void)setAllowsUpdates:(BOOL)arg1;
- (void)setLayerContentsImage:(id)arg1;
- (float)updateContentsAndWidth;
@end

@interface UIStatusBarBatteryItemView : UIStatusBarItemView
- (_UILegibilityImageSet *)contentsImage;
@end

@interface UIImage ()
- (UIImage *)_flatImageWithColor:(UIColor *)color;
@end

@interface UIApplication ()
- (UIStatusBar *)statusBar;
@end