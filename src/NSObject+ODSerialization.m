//
// NSObject+ODSerialization.m
//
// Copyright (c) 2009-2015 Alexey Nazaroff, AJR
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "NSObject+ODSerialization.h"
#import "ODObjCRuntime.h"
#import "ODObjCIvar.h"
#import "NSObject+ODTransformation.h"
#import "NSObject+ODValidation.h"

@implementation NSObject (ODXSerialization)

- (id)od_serialize {
    NSArray<ODObjCIvar *> *ivars = [self.class od_availableIvars];
    return [NSDictionary dictionaryWithObjects:[ivars od_mapObjects:^id(ODObjCIvar *ivar, NSUInteger idx) {
        return [[self valueForKey:ivar.name] od_serialize] ?: [NSNull null];
    }] forKeys:[ivars od_mapObjects:^id(ODObjCIvar *ivar, NSUInteger idx) {
        NSString *name = ivar.name;
        return ([name hasPrefix:@"_"]) ? [name substringFromIndex:1] : name;
    }]];
}

@end

@implementation NSArray (ODXSerialization)

- (id)od_serialize {
    return (self.count == 0) ? @[] : [self od_mapObjects:^id(id obj, NSUInteger idx) {
        return [obj od_serialize];
    }];
}

@end

@implementation NSDictionary (ODXSerialization)

- (id)od_serialize {
    return (self.count == 0) ? @{} : [self od_mapObjects:^id(id key, id obj) {
        return [obj od_serialize];
    }];
}

@end

@implementation NSString (ODXSerialization)

- (id)od_serialize {
    return self;
}

@end

@implementation NSNumber (ODXSerialization)

- (id)od_serialize {
    return self;
}

@end

@implementation NSNull (ODXSerialization)

- (id)od_serialize {
    return self;
}

@end
