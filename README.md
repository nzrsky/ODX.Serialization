# ODX.Serialization

[![Version](https://img.shields.io/cocoapods/v/ODX.Serialization.svg?style=flat)](http://cocoapods.org/pods/ODX.Serialization)
[![License](https://img.shields.io/cocoapods/l/ODX.Serialization.svg?style=flat)](http://cocoapods.org/pods/ODX.Serialization)
[![Platform](https://img.shields.io/cocoapods/p/ODX.Serialization.svg?style=flat)](http://cocoapods.org/pods/ODX.Serialization)

ODX.Serialization is utility classes for serialization and deserialization Objective-C objects.
It can be used together with NSJSONSerialization or XMLDictionary, FMDB, etc.

## Usage
### Serialization
<sup>(*NSObject+ODSerialization*)</sup>
```objective-c
<NSObject> -(id)od_serialize;
```
Converts any object to NSDictionary or NSArray with NSStrings, NSNumbers and NSNulls. After this new object can be converted to JSON string.

### Deserialization
<sup>(*NSObject+ODDeserialization*)</sup>
```objective-c
<NSObject> +od_constructWithObject:(NSObject *)srcObj error:(NSError **)error;
```
Create object of current class from NSDictionary. Using that it's possible to convert json string to model object.

### Example
Let's create our model class:

```objective-c
@interface Obj : NSObject <ODDataObject>
@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) NSInteger count;
@property (nonatomic, strong) NSArray<Obj *> *items;
@end

@implementation Obj

// We implement ODDataObject protocol's method for specify class of object in `items` array
+ (Class)classOfIvarWithName:(NSString *)ivarName {
    if ([ivarName isEqualToString:@"_items"]) return Obj.class;
    return nil;
}

@end
```

Now, if we fill object and perform `od_serialize` method:
```objective-c
Obj *o = [Obj new];
o.title = @"Title";
o.count = 10;
o.items = @[[Obj new], [Obj new]];

NSLog(%"@", o.od_serialize);
/*
{
   count = 10;
   items = (
       {
           count = 0;
           items = "<null>";
           title = "<null>";
       },
       {
           count = 0;
           items = "<null>";
           title = "<null>";
       }
   );
   title = Title;
}
*/

NSLog(@"%@", [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:o.od_serialize
                                                                            options:0 error:nil]
                                                                            encoding:NSUTF8StringEncoding]);
// {"title":"Title","count":10,"items":[{"title":null,"count":0,"items":null},{"title":null,"count":0,"items":null}]}
```

Deserialization.
```objective-c
NSString *jsonString = @"{\"title\":\"Title\",\"count\":10,\"items\":[{\"title\":null,\"count\":0,\"items\":null},{\"title\":null,\"count\":0,\"items\":null}]}";
NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
Obj *obj = [Obj od_constructWithObject:obj error:nil];

```
<img width="307px" src="https://raw.githubusercontent.com/Rogaven/ODX.Serialization/master/assets/obj_dbg.png" alt="Object debug" title="ODX.Serialization">


## Installation

### CocoaPods
ODX.Serialization is available through [CocoaPods](http://cocoapods.org). It's much more easier. To install
it, simply add the following line to your Podfile:

```ruby
pod "ODX.Serialization"
```
### Manual

For build ODX.Serialization as library you need to put [ODObjcRuntime](https://github.com/Rogaven/ODObjCRuntime.git) and [ODX.Core](https://github.com/Rogaven/ODX.Core.git) projects in the same directory

## Author

Alexey Nazaroff, alexx.nazaroff@gmail.com

## License

ODX.Serialization is available under the MIT license. See the LICENSE file for more info.
