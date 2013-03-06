//
//  AppDelegate.m
//  SwiftzMac
//
//  Created by XiNGRZ on 13-2-26.
//  Copyright (c) 2013年 XiNGRZ. All rights reserved.
//

#import "AppDelegate.h"

#import "Amtium.h"

#import "MainWindow.h"
#import "PreferencesWindow.h"

#import "NetworkInterface.h"

@implementation AppDelegate

+ (void)initialize
{
    NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
    
    [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:SMInitialKey];
    [defaultValues setObject:Nil forKey:SMServerKey];
    [defaultValues setObject:Nil forKey:SMEntryKey];
    [defaultValues setObject:Nil forKey:SMEntryListKey];
    [defaultValues setObject:Nil forKey:SMInterfaceKey];
    [defaultValues setObject:Nil forKey:SMIpKey];
    [defaultValues setObject:[NSNumber numberWithBool:NO] forKey:SMIpManualKey];
    [defaultValues setObject:[NSNumber numberWithBool:NO] forKey:SMKeychainKey];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setMenu:[self statusMenu]];
    [statusItem setTitle:@"Swiftz"];
    [statusItem setHighlightMode:YES];
    
    [self showMainWindow:self];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if ([menuItem action] == @selector(showMainWindow:)) {
        [menuItem setHidden:[[mainWindow amtium] isOnline]];
        return YES;
    }
    
    if ([menuItem action] == @selector(logout:)) {
        [menuItem setHidden:![[mainWindow amtium] isOnline]];
        return YES;
    }
    
    if ([menuItem action] == @selector(showAccount:)) {
        [menuItem setHidden:![[mainWindow amtium] isOnline]];
        if ([[mainWindow amtium] isOnline]) {
            NSString *account = [[mainWindow amtium] account];
            NSString *title = [NSString stringWithFormat:@"Online: %@", account];
            [menuItem setTitle:title];
        }
        return NO;
    }
    
    return YES;
}

- (IBAction)showMainWindow:(id)sender
{
    if (!mainWindow) {
        mainWindow = [[MainWindow alloc] init];
    }
    
    [mainWindow showWindow:self];
}

- (IBAction)showPreferencesWindow:(id)sender
{
    if (!preferencesWindow) {
        preferencesWindow = [[PreferencesWindow alloc] init];
    }
    
    [preferencesWindow showWindow:self];
}

- (IBAction)showAccount:(id)sender
{
    [mainWindow account:sender];
}

- (IBAction)logout:(id)sender
{
    [mainWindow logout:sender];
}

@end
