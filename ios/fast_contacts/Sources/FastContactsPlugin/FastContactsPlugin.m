#import "FastContactsPlugin.h"

@implementation FastContactsPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  Class swiftPluginClass = NSClassFromString(@"FastContactsSwift.SwiftFastContactsPlugin");
  SEL selector = @selector(registerWithRegistrar:);
  if (swiftPluginClass && [swiftPluginClass respondsToSelector:selector]) {
    IMP imp = [swiftPluginClass methodForSelector:selector];
    void (*func)(id, SEL, id) = (void (*)(id, SEL, id))imp;
    func(swiftPluginClass, selector, registrar);
  }
}
@end
