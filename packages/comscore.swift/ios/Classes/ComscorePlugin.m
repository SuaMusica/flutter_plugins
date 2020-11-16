#import "ComscorePlugin.h"
#if __has_include(<comscore/comscore-Swift.h>)
#import <comscore/comscore-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "comscore-Swift.h"
#endif

@implementation ComscorePlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftComscorePlugin registerWithRegistrar:registrar];
}
@end
