//
//  main.m
//  sample
//
//  Created by Alex Nazaroff on 22.05.16.
//  Copyright © 2016 AJR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ODObjectParser.h"
#import "NSObject+ODSerialization.h"
#import "NSObject+ODDeserialization.h"
#import "ODObjCRuntime.h"

@interface ODTestWorker : NSObject <ODDataObject> {
    NSNumber *_tag;
    
}
@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) BOOL isWorker;
@property (nonatomic, assign) NSInteger age;
@property (nonatomic, strong) NSArray<ODTestWorker *> *friends;
@property (nonatomic, strong) NSDictionary *attrs;
@property (nonatomic, strong) NSArray *arr;
@property (nonatomic, strong) ODTestWorker *friend;
@property (nonatomic, strong) id friendContainer;
@property (nonatomic, strong) NSDictionary *wattrs;
@end

@implementation ODTestWorker

- (NSNumber *)tag {
    return _tag;
}

+ (Class)classOfIvarWithName:(NSString *)name {
    if ([name isEqualToString:@"_wattrs"])
        return ODTestWorker.class;
    
    if ([name isEqualToString:@"_friends"] ||
        [name isEqualToString:@"_friendContainer"])
        return ODTestWorker.class;
    
    return nil;
}

@end


NSObject *JSONObjectWithString(NSString *json) {
    return [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        //NSError *err;
        //[ODTestWorker od_constructWithObject:JSONObjectWithString(@"{ \"gag\": 1 }") error:&err];
        //XCTAssert(err.code == ODObjectParserErrorFieldNotFound);
        ;
    }
    return 0;
}
