#import "utils.h"

#import <UIKit/UIKit.h>

__attribute__((constructor)) static void entry(int argc, char **argv)
{
    double systemVersion = [[[UIDevice currentDevice] systemVersion] doubleValue];
    

    if (isJITEnabled()) {
        NSLog(@"yippee");
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:YES forKey:@"JIT-ENABLED"];
        [defaults synchronize]; // Ensure the value is saved immediately
    } else {
        NSLog(@":(");
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:NO forKey:@"JIT-ENABLED"];
        [defaults synchronize]; // Ensure the value is saved immediately
    }
    
    if (getEntitlementValue(@"com.apple.developer.kernel.increased-memory-limit")) {
        NSLog(@"Entitlement Does Exist");
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:YES forKey:@"entitlementExists"];
        [defaults synchronize]; // Ensure the value is saved immediately
    }
    
    if (getEntitlementValue(@"com.apple.developer.kernel.increased-debugging-memory-limit")) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:YES forKey:@"increaseddebugmem"];
        [defaults synchronize]; // Ensure the value is saved immediately
    }
    if (getEntitlementValue(@"com.apple.developer.kernel.extended-virtual-addressing")) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:YES forKey:@"extended-virtual-addressing"];
        [defaults synchronize]; // Ensure the value is saved immediately
    }
        
}
