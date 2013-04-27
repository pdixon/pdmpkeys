//
//  pdmpkeys.m
//
//  A stupidly simple tool to control mpd with mac media keys. Based
//  on https://github.com/sweetfm/SweetFM/blob/master/Source/HMediaKeys.m
//
//  Created by Phillip Dixon on 2013-04-20
//  Copyright (c) 2013 Phillip Dixon. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//
// Media key constants
//
typedef enum {
    PlayPauseKeyDown = 0x100A00,
    PlayPauseKeyUp   = 0x100B00,
    NextKeyDown      = 0x130A00,
    NextKeyUp        = 0x130B00,
    PreviousKeyDown  = 0x140A00,
    PreviousKeyUp    = 0x140B00
} MediaKeys;

#define MediaKeyPlayPauseMask (PlayPauseKeyDown | PlayPauseKeyUp)
#define MediaKeyNextMask (NextKeyDown | NextKeyUp)
#define MediaKeyPreviousMask (PreviousKeyDown | PreviousKeyUp)
#define MediaKeyMask (MediaKeyPlayPauseMask | MediaKeyNextMask | MediaKeyPreviousMask)

CGEventRef tapEventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon) {

    NSEvent *nsEvent;
    NSInteger eventData = 0;

    @autoreleasepool {
        nsEvent = [NSEvent eventWithCGEvent:event];

        if([nsEvent type] == NSSystemDefined)
            eventData = [nsEvent data1];
    }

    if(type==NX_SYSDEFINED && eventData==PlayPauseKeyUp)
    {
        system("mpc toggle");
        return NULL;
    }
    else if(type==NX_SYSDEFINED && eventData==NextKeyUp)
    {
        system("mpc next");
        return NULL;
    }
    else if(type==NX_SYSDEFINED && eventData==PreviousKeyUp)
    {
        system("mpc prev");
        return NULL;
    }

    if(type==NX_SYSDEFINED && (eventData==PlayPauseKeyDown || eventData==NextKeyDown || eventData==PreviousKeyDown))
        return NULL;

    return event;
}

int main()
{
    @autoreleasepool {
        CFMachPortRef eventPort;
        CFRunLoopSourceRef eventSrc;
        CFRunLoopRef runLoop;

        @try {
            CGEventTapOptions opts = kCGEventTapOptionDefault;

            eventPort = CGEventTapCreate (kCGSessionEventTap,
                                          kCGHeadInsertEventTap,
                                          opts,
                                          CGEventMaskBit(NX_SYSDEFINED) | CGEventMaskBit(NX_KEYUP),
                                          tapEventCallback,
                                          nil);

            if (eventPort == NULL)
                NSLog(@"Event port is null");

            eventSrc = CFMachPortCreateRunLoopSource(kCFAllocatorSystemDefault, eventPort, 0);

            if (eventSrc == NULL)
                NSLog(@"No event run loop source found");

            runLoop = CFRunLoopGetCurrent();

            if (eventSrc == NULL)
                NSLog(@"No event run loop");

            CFRunLoopAddSource(runLoop, eventSrc, kCFRunLoopCommonModes);

            while ([[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
        } @catch (NSException *e) {
            NSLog(@"Exception caught while attempting to create run loop for hotkey: %@", e);
        }
    }
}
