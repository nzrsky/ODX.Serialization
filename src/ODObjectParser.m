//
// ODNSObjectParser.m
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

#import "ODObjectParser.h"
#import <ODObjCRuntime/ODObjCRuntime.h>
#import <ODObjCRuntime/ODObjCIvar.h>
#import <ODX.Core/NSObject+ODTransformation.h>
#import <ODX.Core/NSObject+ODValidation.h>

NS_INLINE NSError *ODObjectParserErrorWithCode(ODObjectParserErrorCode code) {
    return [NSError errorWithDomain:@"com.ajr.odx" code:code userInfo:nil];
}

#define ODX_ERR(code)                 if (error) { *error = ODObjectParserErrorWithCode(code); }
#define ODX_OBJ_SETVAL(obj, key, val) [(obj) setValue:(val) forKey:(key)]
#define ODX_OBJ_GETVAL(obj, key)      [(obj) valueForKey:(key)]

static NSString * const kODNSDictionaryType = @"@\"NSDictionary\"";
static NSString * const kODNSArrayType = @"@\"NSArray\"";

@implementation ODObjectParser {
    NSMutableDictionary<NSString *, NSDictionary<NSString *, ODObjCIvar *> *> *_context;
}

- (id)constructObjectWithClass:(Class)cls dataObject:(NSObject *)dataObj error:(NSError * __autoreleasing *)error {
    if (!dataObj || ![self.class isValidDataObject:dataObj]) {
        ODX_ERR(ODObjectParserErrorIvalidObject);
        return nil;
    }
    
    if (!_context) {
        _context = [NSMutableDictionary dictionary];
    }
    
    return [self constructObjectWithClass:cls dataObject:dataObj error:error context:_context];
}

- (id)constructObjectWithClass:(Class)cls dataObject:(NSObject *)dataObj error:(NSError * __autoreleasing *)error context:(NSMutableDictionary<NSString *, NSDictionary<NSString *, ODObjCIvar *> *> *)ctx {
    if ([dataObj od_isValidDictionary]) {
        NSObject<ODDataObject> *res = [cls new];
        NSString *clsName = NSStringFromClass(cls);
        
        NSDictionary<NSString *, ODObjCIvar *> *ivars = ctx[clsName];
        if (!ivars) {
            ivars = [[cls.class od_availableIvars] od_dictionaryWithMappedKeys:^id(ODObjCIvar *obj, NSUInteger idx) {
                NSString *key = obj.name;
                return ([key hasPrefix:@"_"]) ? [key substringFromIndex:1] : key;
            }];
            ctx[clsName] = ivars;
        }
        
        __block NSError *err = nil;
        [(NSDictionary *)dataObj enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull val, BOOL * _Nonnull stop) {
            NSString *stringKey = [key od_validString];
            
            if (!stringKey) {
                NSLog(@"# ODX.Serialization. Error: field '%@' has ivalid value '%@'", key, NSStringFromClass([val class]));
                err = ODObjectParserErrorWithCode(ODObjectParserErrorFieldNotFound);
                return;
            }
            
            ODObjCIvar *ivar = [self findIvarWithKey:stringKey ivars:ivars];
            
            if (!ivar) {
                NSLog(@"# ODX.Serialization. Error: field '%@' isn't found", key);
                err = ODObjectParserErrorWithCode(ODObjectParserErrorFieldNotFound);
                return;
            }
            
            NSString *ivarName = ivar.name;
            id retVal = val;
            
            if ([val isKindOfClass:NSDictionary.class]) {
                if ([ivar.typeEncoding isEqualToString:kODNSDictionaryType]) {
                    if ([res.class respondsToSelector:@selector(classOfIvarWithName:)]) {
                        Class ivarCls = [res.class classOfIvarWithName:ivarName];
                        if (ivarCls) {
                            retVal = [(NSDictionary *)val od_mapObjects:^id(id itemKey, id itemObj) {
                                return [self constructObjectWithClass:ivarCls dataObject:itemObj error:error context:ctx];
                            }];
                        }
                    }
                } else {
                    Class ivarCls = nil;
                    if ([res.class respondsToSelector:@selector(classOfIvarWithName:)]) {
                        ivarCls = [res.class classOfIvarWithName:ivarName];
                    }
                    ivarCls = ivarCls ?: [self.class decodeClass:ivar.typeEncoding];
                    retVal = [self constructObjectWithClass:ivarCls dataObject:val error:error context:ctx];
                }
            } else if ([val isKindOfClass:NSArray.class]) {
                if ([ivar.typeEncoding isEqualToString:kODNSArrayType]) {
                    if ([res.class respondsToSelector:@selector(classOfIvarWithName:)]) {
                        Class ivarCls = [res.class classOfIvarWithName:ivarName];
                        if (ivarCls) {
                            retVal = [(NSArray *)val od_mapObjects:^id(id obj, NSUInteger idx) {
                                return [self constructObjectWithClass:ivarCls dataObject:obj error:error context:ctx];
                            }];
                        }
                    }
                }
            }
            
            ODX_OBJ_SETVAL(res, ivarName, [retVal od_validObject]);
        }];
        
        if (error) {
            *error = err;
        }

        return res;
        
    } else if ([dataObj od_isValidArray]) {
        return [(NSArray *)dataObj od_mapObjects:^id(id obj, NSUInteger idx) {
            return [self constructObjectWithClass:cls dataObject:obj error:error context:ctx];
        }];
    }
    
    return nil;
}

+ (BOOL)isValidDataObject:(id)obj {
    return [NSJSONSerialization isValidJSONObject:obj];
}

+ (Class)decodeClass:(NSString *)str {
    static NSUInteger const padding = 3;
    return (str.length > padding) ? NSClassFromString([str substringWithRange:NSMakeRange(padding-1, str.length-padding)]) : NSObject.class;
}

- (ODObjCIvar *)findIvarWithKey:(NSString *)key ivars:(NSDictionary<NSString *, ODObjCIvar *> *)ivars {
    return ivars[key] ?: (((key = [self cleanKey:key])) ? ivars[key] : nil);
}

- (NSString *)cleanKey:(NSString *)key {
    return nil; // [[stringKey stringByReplacingOccurrencesOfString:@":" withString:@""] stringByReplacingOccurrencesOfString:@"-" withString:@""];
}

@end