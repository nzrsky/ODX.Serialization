//
//  ODXCore_Test.m
//  ODX.Core
//
//  Created by Alex Nazaroff on 12.01.10.
//  Copyright © 2009-2015 AJR. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ODObjectParser.h"
#import "NSObject+ODSerialization.h"
#import "NSObject+ODDeserialization.h"

@interface Obj : NSObject <ODDataObject>
@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) NSInteger count;
@property (nonatomic, strong) NSArray<Obj *> *items;
@end

@implementation Obj

+ (Class)classOfIvarWithName:(NSString *)ivarName {
    if ([ivarName isEqualToString:@"_items"]) return Obj.class;
    return nil;
}

@end

@interface ODTestWorker : NSObject <ODDataObject> {
    NSNumber *_tag;
    
}
@property (nonatomic, copy) NSString *name;
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

@interface ODTestNobleWorker : ODTestWorker
@property (nonatomic, strong) NSString *family;
@end

@implementation ODTestNobleWorker
@end



@interface ODXDeserialization_Test : XCTestCase
@end

@implementation ODXDeserialization_Test

NSObject *JSONObjectWithString(NSString *json) {
    return [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
}

- (void)testODConstructWithObject_error {
    NSObject *obj = JSONObjectWithString(@"{ \"friendContainer\":{\"name\": \"John Doe\"}, \"isWorker\": true, \"name\": \"John Doe\", \"age\": 31, \"tag\": 1, \"attrs\":{ \"a\": true},  \"arr\":[ \"a\", true], \"friends\": [ { \"isWorker\": false, \"name\": \"Steve Jobs\", \"age\": -1, \"attrs\":{ \"a\": false}, \"friends\": null, \"tag\": 0.5 } ], \"friend\":{ \"isWorker\": false, \"name\": \"Steve Jobs\", \"age\": -1, \"attrs\":{ \"a\": false}, \"friends\": null, \"tag\": 0.5 }}");
    // NSLog(@"Obj: %@", obj);
    
    ODTestWorker *worker = [ODTestWorker od_constructWithObject:obj error:nil];
    XCTAssert(worker.isWorker == YES);
    XCTAssert([worker.name isEqualToString:@"John Doe"]);
    XCTAssert(worker.age == 31);
    XCTAssert([worker.tag isEqualToNumber:@1]);
    XCTAssert([worker.attrs isEqualToDictionary:@{@"a": @YES}]);
    XCTAssert([worker.arr isEqualToArray:(@[@"a", @YES])]);
    XCTAssert([((ODTestWorker *)worker.friendContainer) isKindOfClass:ODTestWorker.class]);
    XCTAssert([((ODTestWorker *)worker.friendContainer) isKindOfClass:ODTestWorker.class] && [((ODTestWorker *)worker.friendContainer).name isEqualToString:@"John Doe"]);
    
    NSArray *fr = worker.friends;
    
    worker = worker.friend;
    XCTAssert([worker isKindOfClass:ODTestWorker.class]);
    XCTAssert(worker.isWorker == NO);
    XCTAssert([worker.name isEqualToString:@"Steve Jobs"]);
    XCTAssert(worker.age == -1);
    XCTAssert([worker.attrs isEqualToDictionary:@{@"a": @NO}]);
    XCTAssert([worker.tag isEqualToNumber:@0.5]);
    XCTAssert(!worker.friends);
    
    worker = fr.firstObject;
    XCTAssert(fr.count == 1);
    XCTAssert([worker isKindOfClass:ODTestWorker.class]);
    XCTAssert(worker.isWorker == NO);
    XCTAssert([worker.name isEqualToString:@"Steve Jobs"]);
    XCTAssert(worker.age == -1);
    XCTAssert([worker.attrs isEqualToDictionary:@{@"a": @NO}]);
    XCTAssert([worker.tag isEqualToNumber:@0.5]);
    XCTAssert(!worker.friends);
    
    NSError *err;
    [ODTestWorker od_constructWithObject:JSONObjectWithString(@"1") error:&err];
    XCTAssert(err.code == ODObjectParserErrorIvalidObject);
    
    [ODTestWorker od_constructWithObject:JSONObjectWithString(@"{ \"gag\": 1 }") error:&err];
    XCTAssert(err.code == ODObjectParserErrorFieldNotFound);
    
    obj = JSONObjectWithString(@"[{ \"isWorker\": true, \"name\": \"John Doe\", \"age\": 31, \"tag\": 1, \"friends\":null}, { \"isWorker\": false, \"name\": \"Steve Jobs\", \"age\": -1, \"tag\": 0.5, \"friends\":null}]");
    NSArray<ODTestWorker *> *arr = [ODTestWorker od_constructWithObject:obj error:&err];
    XCTAssert(arr.count == 2);
    
    worker = arr.firstObject;
    XCTAssert(worker.isWorker == YES);
    XCTAssert([worker.name isEqualToString:@"John Doe"]);
    XCTAssert(worker.age == 31);
    XCTAssert([worker.tag isEqualToNumber:@1]);
    XCTAssert(!worker.friends);
    
    worker = arr.lastObject;
    XCTAssert(worker.isWorker == NO);
    XCTAssert([worker.name isEqualToString:@"Steve Jobs"]);
    XCTAssert(worker.age == -1);
    XCTAssert([worker.tag isEqualToNumber:@0.5]);
    XCTAssert(!worker.friends);
    
    obj = @{ @"wattrs": @{ @"worker": @{ @"name": @"W" } }};
    worker = [ODTestWorker od_constructWithObject:obj error:&err];
    worker = worker.wattrs[@"worker"];
    XCTAssert(worker);
    XCTAssert([worker.name isEqualToString:@"W"]);
    
    
    NSObject *snowJson = JSONObjectWithString(@"{ \"family\": \"Snow\", \"name\": \"John\" }");
    ODTestNobleWorker *snow = [ODTestNobleWorker od_constructWithObject:snowJson error:nil];
    XCTAssert([snow.family isEqualToString:@"Snow"]);
    XCTAssert([snow.name isEqualToString:@"John"]);
}

@end

@interface ODXSerialization_Test : XCTestCase {
    ODTestWorker *_worker;
}
@end

@implementation ODXSerialization_Test

- (void)setUp {
    NSString *jsonString = @"{\"title\":\"Title\",\"count\":10,\"items\":[{\"title\":null,\"count\":0,\"items\":null},{\"title\":null,\"count\":0,\"items\":null}]}";
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    Obj *obj = [Obj od_constructWithObject:jsonDict error:nil];
    XCTAssert(obj);
}

- (void)testODSerialize {
    NSDictionary *obj = nil;
    
    obj = [@[] od_serialize];
    XCTAssert([obj isKindOfClass:NSArray.class]);
    
    obj = [@{} od_serialize];
    XCTAssert([obj isKindOfClass:NSDictionary.class]);
    
    obj = [@"" od_serialize];
    XCTAssert([obj isKindOfClass:NSString.class]);
    
    obj = [@0 od_serialize];
    XCTAssert([obj isKindOfClass:NSNumber.class]);
    
    obj = [@[ @1, @"2" ] od_serialize];
    XCTAssert([obj isEqual:(@[@1, @"2"])]);
    
    obj = [@{@1: @"a", @"b": @2} od_serialize];
    XCTAssert([obj isEqual:(@{@1: @"a", @"b": @2})]);
    
    _worker = [ODTestWorker new];
    _worker.name = @"John Doe";
    _worker.isWorker = YES;
    _worker.age = 10;
    _worker.friends = @[ ({
        ODTestWorker *w = [ODTestWorker new];
        w.name = @"Alice";
        w.isWorker = NO;
        w.age = -1;
        w.friend = w.friends.firstObject;
        w.attrs = @{ @1: @"a", @"a": @2 };
        w.wattrs = @{ @1: [ODTestWorker new] };
        w.arr = @[ @"a", @"b" ];
        w.friendContainer = w.friend;
        w;
    })];
    _worker.friend = _worker.friends.firstObject;
    _worker.attrs = @{ @1: @"a", @"a": @2 };
    _worker.wattrs = @{ @1: _worker.friend };
    _worker.arr = @[ @"a", @"b" ];
    _worker.friendContainer = _worker.friend;
    
    obj = [_worker od_serialize];
    XCTAssert([obj isKindOfClass:NSDictionary.class]);
    XCTAssert([obj[@"name"] isEqualToString:_worker.name]);
    XCTAssert([obj[@"isWorker"] isEqualToNumber:@YES]);
    XCTAssert([obj[@"age"] isEqualToNumber:@10]);
    XCTAssert([obj[@"arr"] isEqualToArray:_worker.arr]);
    
    XCTAssert([obj[@"attrs"] isEqualToDictionary:_worker.attrs]);
    
    NSArray *friends = obj[@"friends"];
    NSDictionary *friend = friends.firstObject;
    XCTAssert([friends isKindOfClass:NSArray.class]);
    XCTAssert([obj[@"friendContainer"] isEqualToDictionary:friend]);
    XCTAssert([obj[@"friend"] isEqualToDictionary:friend]);
    XCTAssert([obj[@"wattrs"] isEqualToDictionary:@{@1: friend}]);
    
    XCTAssert([friend isKindOfClass:NSDictionary.class]);
    XCTAssert([friend[@"name"] isEqualToString:_worker.friend.name]);
    XCTAssert([friend[@"isWorker"] isEqualToNumber:@NO]);
    XCTAssert([friend[@"age"] isEqualToNumber:@(-1)]);
    XCTAssert([friend[@"arr"] isEqualToArray:_worker.friend.arr]);
    
    ODTestNobleWorker *snow = [ODTestNobleWorker new];
    snow.name = @"John"; snow.family = @"Snow";
    obj = [snow od_serialize];
    XCTAssert([obj[@"family"] isEqualToString:@"Snow"]);
    XCTAssert([obj[@"name"] isEqualToString:@"John"]);
}

@end

