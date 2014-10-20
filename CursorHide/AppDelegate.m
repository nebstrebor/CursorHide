//
//  AppDelegate.m
//  CursorHide
//
//  Created by Geoff Greer on 2/8/14.
//  Copyright (c) 2014 Geoff Greer. All rights reserved.
//

#include <ApplicationServices/ApplicationServices.h>
#include <AppKit/NSStatusBar.h>

#import "AppDelegate.h"

@implementation AppDelegate

- (void)propStringHack {
    void CGSSetConnectionProperty(int, int, CFStringRef, CFBooleanRef);
    int _CGSDefaultConnection();
    CFStringRef propertyString;

    // Hack to make background cursor setting work
    propertyString = CFStringCreateWithCString(NULL, "SetsCursorInBackground", kCFStringEncodingUTF8);
    CGSSetConnectionProperty(_CGSDefaultConnection(), _CGSDefaultConnection(), propertyString, kCFBooleanTrue);
    CFRelease(propertyString);
}

- (void)reloadSettings {
    timeout = 5;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    [self reloadSettings];
}

- (void)hideCursor {
    CGDisplayHideCursor(kCGDirectMainDisplay);
}

- (void)startTimer {
    [timer invalidate];
    if (enabled) {
        timer = [NSTimer scheduledTimerWithTimeInterval: timeout
                                             target: self
                                           selector: @selector(hideCursor)
                                           userInfo: nil
                                            repeats: YES]; //repeating every n seconds just to ensure it stays hidden if something unhides it.
        [timer setTolerance: 0.1]; // Save power
    }
}

- (IBAction)toggle:(id)sender {
    enabled = !enabled;
    if (enabled) {
        [statusItem setImage: [NSImage imageNamed:@"cursor"]];
        [_state setTitle: @"Disable CursorHide"];
    } else {
        [statusItem setImage: [NSImage imageNamed:@"cursor_translucent"]];
        [_state setTitle: @"Enable CursorHide"];
    }
}

- (IBAction)quit:(id)sender {
    [defaults synchronize];
    exit(0);
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSStatusBar *bar = [NSStatusBar systemStatusBar];
    statusItem = [bar statusItemWithLength: NSVariableStatusItemLength];
    [statusItem setImage: [NSImage imageNamed:@"cursor"]];
    [statusItem setHighlightMode: YES];
    [statusItem setMenu: _menu];

    [self reloadSettings];
    [defaults addObserver: self
               forKeyPath: @"cursorHideTimeout"
                  options: NSKeyValueObservingOptionNew
                  context: NULL];

    enabled = true;

    [self propStringHack];
    [self startTimer];

    NSUInteger resetTimerMask = NSMouseMovedMask | NSLeftMouseDownMask | NSRightMouseDownMask;
    
    [NSEvent addGlobalMonitorForEventsMatchingMask:resetTimerMask handler:^(NSEvent *event) {
        CGError err = CGDisplayShowCursor(kCGDirectMainDisplay);
        if (err) {
            NSLog(@"Error showing cursor: %u", err);
        }
        [self startTimer];
    }];
}

@end
