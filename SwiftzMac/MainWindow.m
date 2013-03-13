//
//  MainWindow.m
//  SwiftzMac
//
//  Created by XiNGRZ on 13-3-4.
//  Copyright (c) 2013年 XiNGRZ. All rights reserved.
//

#import "AppDelegate.h"
#import "MainWindow.h"
#import "SpinningWindow.h"

#import "Amtium.h"
#import "SSKeychain.h"

@implementation MainWindow

- (id)init
{
    if (![super initWithWindowNibName:@"MainWindow"]) {
        return nil;
    }
    return self;
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        appdelegate = [[NSApplication sharedApplication] delegate];

        amtium = [[Amtium alloc] initWithDelegate:self
                                 didErrorSelector:@selector(amtiumDidError:)
                                 didCloseSelector:@selector(amtiumDidClose:)];
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];

    if ([appdelegate initialUse]) {
        // 如果是初次使用，执行初始化过程

        [appdelegate setInitialUse:NO];

        spinningWindow = [[SpinningWindow alloc]
                          initWithMessage:NSLocalizedString(@"MSG_PREPARING", @"Preparing...")
                          delegate:self
                          didCancelSelector:@selector(initialDidCancel:)];

        [NSApp beginSheet:[spinningWindow window]
           modalForWindow:[self window]
            modalDelegate:self
           didEndSelector:nil
              contextInfo:nil];

        [amtium searchServer:@selector(initialStepOneWithServer:)];
    } else if (![appdelegate ipManual] && ![[appdelegate ipAddresses] containsObject:[appdelegate ip]]) {
        // 如果不是手动指定IP且IP不在列表中，说明IP已变更，提示重新设置
        NSLog(@"ip changed");
        [appdelegate showPreferencesWindow:self];
    } else {
        [amtium setServer:[appdelegate server]];
        [amtium setEntry:[appdelegate entry]];
        [amtium setMac:[appdelegate mac]];
        [amtium setIp:[appdelegate ip]];
    }

    NSArray *accounts = [SSKeychain accountsForService:@"SwiftzMac"];
    if (accounts != nil && [accounts count] > 0) {
        NSDictionary *account = [accounts objectAtIndex:0];
        
        NSString *username = [account objectForKey:@"acct"];
        NSString *password = [SSKeychain passwordForService:@"SwiftzMac"
                                                    account:username];

        [[self username] setStringValue:username];
        [[self password] setStringValue:password];
    }
}

- (void)initialStepOneWithServer:(NSString *)server
{
    NSLog(@"got server: %@", server);
    [appdelegate setServer:server];
    [amtium fetchEntries:@selector(initialStepTwoWithEntries:)];
}

- (void)initialStepTwoWithEntries:(NSArray *)entries
{
    [appdelegate setEntries:entries];

    NSString *firstEntry = [entries objectAtIndex:0];
    [appdelegate setEntry:firstEntry];

    [NSApp endSheet:[spinningWindow window]];
    [spinningWindow close];
    spinningWindow = nil;

    [amtium setServer:[appdelegate server]];
    [amtium setEntry:[appdelegate entry]];
    [amtium setMac:[appdelegate mac]];
    [amtium setIp:[appdelegate ip]];

    [appdelegate showPreferencesWindow:self];
}

- (void)initialDidCancel:(id)sender
{
    [NSApp endSheet:[spinningWindow window]];
    [spinningWindow close];
    spinningWindow = nil;
    
    [[NSApplication sharedApplication] terminate:self];
}

- (IBAction)login:(id)sender
{
    NSLog(@"login");

    spinningWindow = [[SpinningWindow alloc]
                      initWithMessage:NSLocalizedString(@"MSG_LOGGINGIN", @"Logging in...")
                      delegate:self
                      didCancelSelector:@selector(loginDidCancel:)];

    [NSApp beginSheet:[spinningWindow window]
       modalForWindow:[self window]
        modalDelegate:self
       didEndSelector:nil
          contextInfo:nil];

    [amtium setServer:[appdelegate server]];
    [amtium setEntry:[appdelegate entry]];
    [amtium setMac:[appdelegate mac]];
    [amtium setIp:[appdelegate ip]];

    [amtium loginWithUsername:[[self username] stringValue]
                     password:[[self password] stringValue]
               didEndSelector:@selector(didLoginWithSuccess:message:)];
}

- (void)loginDidCancel:(id)sender
{
    [NSApp endSheet:[spinningWindow window]];
    [spinningWindow close];
    spinningWindow = nil;
}

- (void)didLoginWithSuccess:(NSNumber *)success
                    message:(NSString *)message
{
    [NSApp endSheet:[spinningWindow window]];
    [spinningWindow close];
    spinningWindow = nil;

    if ([success boolValue]) {
        [self close];
        [appdelegate setOnline:YES];
        [appdelegate showNotification:message];
        
        [SSKeychain setPassword:[[self password] stringValue]
                     forService:@"SwiftzMac"
                        account:[[self username] stringValue]];
    } else {
        NSString *title = NSLocalizedString(@"MSG_LOGINFAILED", @"Login failed.");

        NSAlert *alert = [NSAlert alertWithMessageText:title
                                         defaultButton:@"OK"
                                       alternateButton:@""
                                           otherButton:@""
                             informativeTextWithFormat:@"%@", message];

        [alert beginSheetModalForWindow:[self window]
                          modalDelegate:self
                         didEndSelector:nil
                            contextInfo:nil];
    }
}

- (IBAction)logout:(id)sender
{
    NSLog(@"logout");
    [amtium logout:nil];
    [appdelegate showMainWindow:sender];
    [appdelegate setOnline:NO];
}

- (IBAction)account:(id)sender
{
    NSLog(@"show account");
}

- (Amtium *)amtium
{
    return amtium;
}

- (void)amtiumDidClose:(NSNumber *)reason
{
    [amtium logout:nil];
    [appdelegate showMainWindow:self];
    [appdelegate setOnline:NO];

    NSString *title = NSLocalizedString(@"MSG_DISCONNECTED", @"Disconnected.");
    NSString *message = @"";

    switch ([reason integerValue]) {
        case 0:
            message = NSLocalizedString(@"MSG_DISCONNECTED_0",
                                        @"Failed to keep connection alive, please login again.");
            break;

        case 1:
            message = NSLocalizedString(@"MSG_DISCONNECTED_1",
                                        @"You have been disconnected forcibly.");
            break;

        case 2:
            message = NSLocalizedString(@"MSG_DISCONNECTED_2",
                                        @"Your traffic has run out, please login again.");
            break;
            
        default:
            message = [NSString stringWithFormat:NSLocalizedString(@"MSG_DISCONNECTED_UNKNOWN",
                                                                   @"Reason code: %i"), reason];
            break;
    }

    NSAlert *alert = [NSAlert alertWithMessageText:title
                                     defaultButton:NSLocalizedString(@"OK", @"OK")
                                   alternateButton:@""
                                       otherButton:@""
                         informativeTextWithFormat:@"%@", message];

    [alert beginSheetModalForWindow:[self window]
                      modalDelegate:self
                     didEndSelector:nil
                        contextInfo:nil];

    // TODO: 自动重新登录
}

- (void)amtiumDidError:(NSError *)error
{
    [amtium logout:nil];
    [appdelegate showMainWindow:self];

    NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"MSG_ERROR", @"An error occured.")
                                     defaultButton:NSLocalizedString(@"OK", @"OK")
                                   alternateButton:@""
                                       otherButton:@""
                         informativeTextWithFormat:@""];

    [alert beginSheetModalForWindow:[self window]
                      modalDelegate:self
                     didEndSelector:nil
                        contextInfo:nil];
}

- (void)windowWillClose:(NSNotification *)notification
{
    NSLog(@"will close");
    if (![amtium online]) {
        [[NSApplication sharedApplication] terminate:self];
    }
}

@end
