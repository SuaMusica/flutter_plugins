#import "SmadsPlugin.h"
#if __has_include(<smads/smads-Swift.h>)
#import <smads/smads-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "smads-Swift.h"
#endif

@implementation SmadsPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftSmadsPlugin registerWithRegistrar:registrar];
}
@end
