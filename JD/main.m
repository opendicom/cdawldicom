//
//  main.m
//  JD
//
//  Created by pcs on 29/1/21.
//  Copyright © 2021 saluduy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JD.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSDictionary *J=@{@"dataset":@{@"00000001-00080005_CS":@[@"ISO_IR 100"]}};
        NSMutableData *D=[NSMutableData data];
        JD(J,D);
        [D writeToFile:@"/Users/Shared/D.dcm" atomically:NO];
    }
    return 0;
}
