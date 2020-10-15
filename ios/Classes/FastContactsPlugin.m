#import "FastContactsPlugin.h"
#if __has_include(<fast_contacts/fast_contacts-Swift.h>)
#import <fast_contacts/fast_contacts-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "fast_contacts-Swift.h"
#endif

@implementation FastContactsPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFastContactsPlugin registerWithRegistrar:registrar];
}
@end
