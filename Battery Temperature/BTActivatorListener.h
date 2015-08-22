//
//  BTActivatorListener.h
//  Battery Temperature
//
//  Created by Colin Campbell on 8/21/15.
//
//

#import <Foundation/Foundation.h>
#import <libactivator/libactivator.h>

@interface BTActivatorListener : NSObject<LAListener>

- (id)initWithListenerName:(NSString *)name;

@end
