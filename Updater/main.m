/**
 * Name: Backgrounder
 * Type: iPhone OS SpringBoard extension (MobileSubstrate-based)
 * Description: allow applications to run in the background
 * Author: Lance Fetters (aka. ashikase)
 * Last-modified: 2010-04-29 22:25:08
 */

/**
 * Copyright (C) 2008-2010  Lance Fetters (aka. ashikase)
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with the
 *    distribution.
 *
 * 3. The name of the author may not be used to endorse or promote
 *    products derived from this software without specific prior
 *    written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS
 * OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
 * IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */


#define kFirstRun                @"firstRun"

#define kGlobal                  @"global"
#define kOverrides               @"overrides"

#define kBackgroundingMethod     @"backgroundingMethod"
#define kBadgeEnabled            @"badgeEnabled"
#define kStatusBarIconEnabled    @"statusBarIconEnabled"
#define kPersistent              @"persistent"
#define kAlwaysEnabled           @"alwaysEnabled"

// Outdated preferences
#define kBadgeEnabledForAll      @"badgeEnabledForAll"
#define kBlacklistedApps         @"blacklistedApplications"
#define kEnabledApps             @"enabledApplications"


int main(int argc, char **argv)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    // Get preferences for all applications
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // Get preferences for Backgrounder
    NSDictionary *prefs = [defaults persistentDomainForName:@APP_ID];
    if (prefs == nil)
        // Preferences do not exist; nothing to convert
        return 0;

    // Check for existance of no-longer-used preferences
    BOOL needsConversion = NO;
    NSArray *array = [NSArray arrayWithObjects:
        kBadgeEnabled, kBadgeEnabledForAll, kPersistent, kBlacklistedApps, kEnabledApps, nil];
    for (NSString *key in array) {
        if ([prefs objectForKey:key] != nil) {
            needsConversion = YES;
            break;
        }
    }

    if (needsConversion) {
        // Create variables for old settings, set default values
        BOOL badgeEnabled = NO;
        BOOL badgeEnabledForAll = YES;
        BOOL persistent = YES;

        NSArray *blacklistedApps = nil;
        NSArray *enabledApps = nil;

        // Load stored settings, if they exist
        id value = [prefs objectForKey:kBadgeEnabled];
        if (value != nil && [value isKindOfClass:[NSNumber class]])
            badgeEnabled = [value boolValue];

        value = [prefs objectForKey:kBadgeEnabledForAll];
        if (value != nil && [value isKindOfClass:[NSNumber class]])
            badgeEnabledForAll = [value boolValue];

        value = [prefs objectForKey:kPersistent];
        if (value != nil && [value isKindOfClass:[NSNumber class]])
            persistent = [value boolValue];

        value = [prefs objectForKey:kBlacklistedApps];
        if (value != nil && [value isKindOfClass:[NSArray class]])
            blacklistedApps = value;

        value = [prefs objectForKey:kEnabledApps];
        if (value != nil && [value isKindOfClass:[NSArray class]])
            enabledApps = value;

        // Create global settings
        NSDictionary *global = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithInteger:2], kBackgroundingMethod,
            [NSNumber numberWithBool:badgeEnabled], kBadgeEnabled,
            [NSNumber numberWithBool:NO], kStatusBarIconEnabled,
            [NSNumber numberWithBool:persistent], kPersistent,
            [NSNumber numberWithBool:NO], kAlwaysEnabled,
            nil];

        // Create overrides
        NSMutableDictionary *overrides = [NSMutableDictionary dictionary];

        // Add entries for blacklisted applications (use "Native" method)
        for (NSString *displayId in blacklistedApps) {
            NSMutableDictionary *dict = [global mutableCopy];
            [dict setObject:[NSNumber numberWithInteger:1] forKey:kBackgroundingMethod];
            [overrides setObject:dict forKey:displayId];
            [dict release];
        }

        // Add entries for always-enabled applications
        for (NSString *displayId in enabledApps) {
            // Make sure settings for this app do not yet exist
            // NOTE: Technically, always-enabled would have been pointless with blacklisted
            NSMutableDictionary *dict = [overrides objectForKey:displayId];
            if (dict == nil)
                dict = (NSMutableDictionary *)global;
            dict = [dict mutableCopy];
            [dict setObject:[NSNumber numberWithBool:YES] forKey:kAlwaysEnabled];
            [overrides setObject:dict forKey:displayId];
            [dict release];
        }

        // Create structure for updated preferences
        // NOTE: firstRun will always be NO as preferences existed
        //       (and hence the preferences application had been run)
        prefs = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithBool:NO], kFirstRun,
            global, kGlobal,
            overrides, kOverrides,
            nil];

        // Save updated preferences to disk, replacing old
        [defaults setPersistentDomain:prefs forName:@APP_ID];
        [defaults synchronize];
    }

    [pool release];
    return 0;
}

/* vim: set filetype=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
