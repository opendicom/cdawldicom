//
//  NSTask+function.h
//  cda2mwl
//
//  Created by jacquesfauquex on 2021-01-28.
//  Copyright © 2021 saluduy. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
int task(NSString *launchPath, NSArray *launchArgs, NSData *writeData, NSMutableData *readData);

@interface NSTask_function : NSTask

@end

NS_ASSUME_NONNULL_END
