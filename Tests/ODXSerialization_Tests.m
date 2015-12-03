//
//  ODXCore_Test.m
//  ODX.Core
//
//  Created by Alex Nazaroff on 12.01.10.
//  Copyright © 2009-2015 AJR. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ODNSObjectParser.h"
#import "NSObject+ODSerialization.h"
#import "NSObject+ODDeserialization.h"

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
    if ([name isEqualToString:@"_wattrs"]) return ODTestWorker.class;
    return ([name isEqualToString:@"_friends"] || [name isEqualToString:@"_friendContainer"]) ? ODTestWorker.class : nil;
}

@end

@interface ODXDeserialization_Test : XCTestCase
@end

@implementation ODXDeserialization_Test

NSObject *JSONObjectWithString(NSString *json) {
    return [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
}

- (void)testConstruct {
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
    //    [ODTestWorker od_constructWithObject:JSONObjectWithString(@"{ \"gag\": 1 }") error:&err];
    //    XCTAssert(err.code == ODNSObjectParserErrorFieldNotFound);
    
    [ODTestWorker od_constructWithObject:JSONObjectWithString(@"1") error:&err];
    XCTAssert(err.code == ODNSObjectParserErrorIvalidObject);
    
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
}

@end

@interface ODXSerialization_Test : XCTestCase
@end

@implementation ODXSerialization_Test
@end

//
//    //
//    //  AppDelegate.m
//    //  App
//    //
//    //  Created by Alex Nazaroff on 26.11.15.
//    //  Copyright © 2015 AJR. All rights reserved.
//    //
//
//    #import "AppDelegate.h"
//    #import "NSObject+ODSerialization.h"
//    #import "NSObject+ODDeserialization.h"
//    #import "ODNSObjectParser.h"
//
//    @interface AppDelegate ()
//    @property (weak) IBOutlet NSWindow *window;
//    @end
//
//    @interface ODTestWorker : NSObject <ODDataObject> {
//        NSNumber *_tag;
//        
//    }
//    @property (nonatomic, strong) NSString *name;
//    @property (nonatomic, assign) BOOL isWorker;
//    @property (nonatomic, assign) NSInteger age;
//    @property (nonatomic, strong) NSArray<ODTestWorker *> *friends;
//    @property (nonatomic, strong) NSDictionary *attrs;
//    @property (nonatomic, strong) NSArray *arr;
//    @property (nonatomic, strong) ODTestWorker *friend;
//    @property (nonatomic, strong) id friendContainer;
//    @property (nonatomic, strong) NSDictionary *wattrs;
//    @end
//
//    @implementation ODTestWorker
//
//    - (NSNumber *)tag {
//        return _tag;
//    }
//
//    + (Class)classOfIvarWithName:(NSString *)name {
//        if ([name isEqualToString:@"_wattrs"]) return ODTestWorker.class;
//        return ([name isEqualToString:@"_friends"] || [name isEqualToString:@"_friendContainer"]) ? ODTestWorker.class : nil;
//    }
//
//    @end
//
//    #define ODAssert(x) assert(x);
//
//    @implementation AppDelegate
//
//    NSObject *JSONObjectWithString(NSString *json) {
//        return [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
//    }
//
//    - (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
//        NSObject *obj = JSONObjectWithString(@"{ \"friendContainer\":{\"name\": \"John Doe\"}, \"isWorker\": true, \"name\": \"John Doe\", \"age\": 31, \"tag\": 1, \"attrs\":{ \"a\": true},  \"arr\":[ \"a\", true], \"friends\": [ { \"isWorker\": false, \"name\": \"Steve Jobs\", \"age\": -1, \"attrs\":{ \"a\": false}, \"friends\": null, \"tag\": 0.5 } ], \"friend\":{ \"isWorker\": false, \"name\": \"Steve Jobs\", \"age\": -1, \"attrs\":{ \"a\": false}, \"friends\": null, \"tag\": 0.5 }}");
//        // NSLog(@"Obj: %@", obj);
//        
//        ODTestWorker *worker = [ODTestWorker od_constructWithObject:obj error:nil];
//        ODAssert(worker.isWorker == YES);
//        ODAssert([worker.name isEqualToString:@"John Doe"]);
//        ODAssert(worker.age == 31);
//        ODAssert([worker.tag isEqualToNumber:@1]);
//        ODAssert([worker.attrs isEqualToDictionary:@{@"a": @YES}]);
//        ODAssert([worker.arr isEqualToArray:(@[@"a", @YES])]);
//        ODAssert([((ODTestWorker *)worker.friendContainer) isKindOfClass:ODTestWorker.class]);
//        ODAssert([((ODTestWorker *)worker.friendContainer) isKindOfClass:ODTestWorker.class] && [((ODTestWorker *)worker.friendContainer).name isEqualToString:@"John Doe"]);
//        
//        NSArray *fr = worker.friends;
//        
//        worker = worker.friend;
//        ODAssert([worker isKindOfClass:ODTestWorker.class]);
//        ODAssert(worker.isWorker == NO);
//        ODAssert([worker.name isEqualToString:@"Steve Jobs"]);
//        ODAssert(worker.age == -1);
//        ODAssert([worker.attrs isEqualToDictionary:@{@"a": @NO}]);
//        ODAssert([worker.tag isEqualToNumber:@0.5]);
//        ODAssert(!worker.friends);
//        
//        worker = fr.firstObject;
//        ODAssert(fr.count == 1);
//        ODAssert([worker isKindOfClass:ODTestWorker.class]);
//        ODAssert(worker.isWorker == NO);
//        ODAssert([worker.name isEqualToString:@"Steve Jobs"]);
//        ODAssert(worker.age == -1);
//        ODAssert([worker.attrs isEqualToDictionary:@{@"a": @NO}]);
//        ODAssert([worker.tag isEqualToNumber:@0.5]);
//        ODAssert(!worker.friends);
//        
//        NSError *err;
//        //    [ODTestWorker od_constructWithObject:JSONObjectWithString(@"{ \"gag\": 1 }") error:&err];
//        //    ODAssert(err.code == ODNSObjectParserErrorFieldNotFound);
//        
//        [ODTestWorker od_constructWithObject:JSONObjectWithString(@"1") error:&err];
//        ODAssert(err.code == ODNSObjectParserErrorIvalidObject);
//        
//        obj = JSONObjectWithString(@"[{ \"isWorker\": true, \"name\": \"John Doe\", \"age\": 31, \"tag\": 1, \"friends\":null}, { \"isWorker\": false, \"name\": \"Steve Jobs\", \"age\": -1, \"tag\": 0.5, \"friends\":null}]");
//        NSArray<ODTestWorker *> *arr = [ODTestWorker od_constructWithObject:obj error:&err];
//        ODAssert(arr.count == 2);
//        
//        worker = arr.firstObject;
//        ODAssert(worker.isWorker == YES);
//        ODAssert([worker.name isEqualToString:@"John Doe"]);
//        ODAssert(worker.age == 31);
//        ODAssert([worker.tag isEqualToNumber:@1]);
//        ODAssert(!worker.friends);
//        
//        worker = arr.lastObject;
//        ODAssert(worker.isWorker == NO);
//        ODAssert([worker.name isEqualToString:@"Steve Jobs"]);
//        ODAssert(worker.age == -1);
//        ODAssert([worker.tag isEqualToNumber:@0.5]);
//        ODAssert(!worker.friends);
//        
//        obj = @{ @"wattrs": @{ @"worker": @{ @"name": @"W" } }};
//        worker = [ODTestWorker od_constructWithObject:obj error:&err];
//        worker = worker.wattrs[@"worker"];
//        ODAssert(worker);
//        ODAssert([worker.name isEqualToString:@"W"]);
//    }
//
//    - (void)applicationWillTerminate:(NSNotification *)aNotification {
//        // Insert code here to tear down your application
//    }
//
//    @end
