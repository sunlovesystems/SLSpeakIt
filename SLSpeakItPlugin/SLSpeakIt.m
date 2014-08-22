//
//  SLSpeakIt.m
//  SLSpeakItPlugin
//
//  Created by Transcend on 8/14/14.
//  Copyright (c) 2014 SunLoveSystems. All rights reserved.
//

#import "SLSpeakIt.h"

static SLSpeakIt *speaker = nil;

@implementation SLSpeakIt

+ (void)pluginDidLoad:(NSBundle *)plugin
{
	[self speaker];
}

+ (SLSpeakIt *)speaker
{
    NSLog(@"Launching SLSpeakIt...");
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        speaker = [[self alloc] init];
    });
    
    return speaker;
}

- (id)init
{
    if (self = [super init]) {
        [self addMenuItems];
    }
    return self;
}

- (void)addMenuItems {
    NSMenu *mainMenu = [NSApp mainMenu];
    
    NSMenuItem *editMenu = [mainMenu itemAtIndex:2];
    self.onOffSwitch = [[NSMenuItem alloc] initWithTitle:@"Start SpeakIt" action:@selector(didClickBeginSpeakIt:) keyEquivalent:@""];
    [self.onOffSwitch setTarget:self];
    [[editMenu submenu] addItem:self.onOffSwitch];
}

- (void)didClickBeginSpeakIt:(id)sender
{
    [self.onOffSwitch setTitle:@"Stop SpeakIt"];
    [self.onOffSwitch setAction:@selector(didClickStopSpeakIt:)];
    NSLog(@"Started SpeakIt");
    [[NSNotificationCenter defaultCenter] addObserver:self
                                            selector:@selector(didChangeText:)
                                                name:NSTextDidChangeNotification
                                              object:nil];
}

- (void)didChangeText:(NSNotification *) notification {
    if ([[notification object] isKindOfClass:[NSTextView class]] && [[notification object] isKindOfClass:NSClassFromString(@"DVTSourceTextView")]) {
        self.textView = (NSTextView *)[notification object];
        
        self.rawInputString = self.textView.textStorage.string;
        NSLog(@"The raw input string is: %@", self.rawInputString);
        
        [self tryReplacingStringWithCode];
        NSLog(@"Translated code string is %@", self.translatedCodeString);
    }
}

- (void)tryReplacingStringWithCode
{
    // case - an integer variable
    if ([self.rawInputString rangeOfString:@"Create an integer variable. Call it "].location != NSNotFound) {
        NSLog(@"Found match of lineStart");
        self.lineStart = @"Create an integer variable";
        [self setVariableNameAndValue];
    
    // case - a float variable
    } else if ([self.rawInputString rangeOfString:@"Create a float variable. Call it "].location != NSNotFound) {
        NSLog(@"Found match of lineStart");
        self.lineStart = @"Create a float variable";
        [self setVariableNameAndValue];
    
    // case - a double variable
    } else if ([self.rawInputString rangeOfString:@"Create a double variable. Call it "].location != NSNotFound) {
        NSLog(@"Found match of lineStart");
        self.lineStart = @"Create a double variable";
        [self setVariableNameAndValue];
        
    // case - a string variable
    } else if ([self.rawInputString rangeOfString:@"Create a string variable. Call it "].location != NSNotFound) {
        NSLog(@"Found match of lineStart");
        self.lineStart = @"Create a string variable";
        [self setVariableNameAndValue];
    
    // case - an unsigned integer NSUInteger variable
    } else if ([self.rawInputString rangeOfString:@"Create an unsigned integer variable. Call it "].location != NSNotFound) {
        NSLog(@"Found match of lineStart");
        self.lineStart = @"Create an unsigned integer variable";
        [self setVariableNameAndValue];
    
    // case - an array
    } else if ([self.rawInputString rangeOfString:@"Create an array. Call it "].location != NSNotFound) {
        NSLog(@"Found match of lineStart");
        self.lineStart = @"Create an array";
        [self setArrayOrSetName];
        
    // case - a mutable array
    } else if ([self.rawInputString rangeOfString:@"Create a mutable array. Call it "].location != NSNotFound) {
        NSLog(@"Found match of lineStart");
        self.lineStart = @"Create a mutable array";
        [self setArrayOrSetName];
        
    // case - a set
    } else if ([self.rawInputString rangeOfString:@"Create a set. Call it "].location != NSNotFound) {
        NSLog(@"Found match of lineStart");
        self.lineStart = @"Create a set";
        [self setArrayOrSetName];
    
    // case - a mutable set
    } else if ([self.rawInputString rangeOfString:@"Create a mutable set. Call it "].location != NSNotFound) {
        NSLog(@"Found match of lineStart");
        self.lineStart = @"Create a mutable set";
        [self setArrayOrSetName];
        
    // default case
    } else {
        NSLog(@"No match of lineStart");
    }
}

- (void)setVariableNameAndValue
{
    if ([self.rawInputString rangeOfString:@". Equal to "].location == NSNotFound) {
        NSLog(@"Variable not detected");
    } else {
        // Find and set the variable name
        NSRange varStartRange = [self.rawInputString rangeOfString:@"Call it " options:NSBackwardsSearch];
        NSRange varEndRange = [self.rawInputString rangeOfString:@". Equal to " options:NSBackwardsSearch];
        NSUInteger varLength = (varEndRange.location) - (varStartRange.location+8);
        NSString *varName = [self.rawInputString substringWithRange:NSMakeRange(varStartRange.location+8, varLength)];
        
        // If the variable has a value, find and set it, then call a method to replace
        // on-screen text with code
        if ([self.rawInputString rangeOfString:@". Next.\n"].location == NSNotFound) {
            NSLog(@"Variable value not detected");
            // Set it as an empty value in code here
        } else {
            NSRange valStartRange = [self.rawInputString rangeOfString:@"Equal to " options:NSBackwardsSearch];
            NSRange valEndRange = [self.rawInputString rangeOfString:@". Next.\n" options:NSBackwardsSearch];
            NSUInteger valLength = (valEndRange.location) - (valStartRange.location+9);
            NSString *value = [self.rawInputString substringWithRange:NSMakeRange(valStartRange.location+9, valLength)];
            if ([self.lineStart isEqualToString:@"Create an integer variable"]) {
                int variableValue = [value intValue];
                self.translatedCodeString = [NSString stringWithFormat:@"int %@ = %d;\n\t", varName, variableValue];
                [self replaceLineWithTranslatedCodeString];
            } else if ([self.lineStart isEqualToString:@"Create a float variable"]) {
                float variableValue = [value floatValue];
                self.translatedCodeString = [NSString stringWithFormat:@"float %@ = %f;\n\t", varName, variableValue];
                [self replaceLineWithTranslatedCodeString];
            } else if ([self.lineStart isEqualToString:@"Create a double variable"]) {
                double variableValue = [value doubleValue];
                self.translatedCodeString = [NSString stringWithFormat:@"double %@ = %f;\n\t", varName, variableValue];
                [self replaceLineWithTranslatedCodeString];
            } else if ([self.lineStart isEqualToString:@"Create a string variable"]) {
                self.translatedCodeString = [NSString stringWithFormat:@"NSString *%@ = @\"%@\";\n\t", varName, value];
                [self replaceLineWithTranslatedCodeString];
            } else if ([self.lineStart isEqualToString:@"Create an unsigned integer variable"]) {
                NSUInteger variableValue = [value intValue];
                self.translatedCodeString = [NSString stringWithFormat:@"NSUInteger %@ = %lu;\n\t", varName, (unsigned long)variableValue];
                [self replaceLineWithTranslatedCodeString];
            } else {
                value = @"Placeholder";
                varName = @"Placeholder";
            }
        }
    }
}

- (void)setArrayOrSetName
{
    if ([self.rawInputString rangeOfString:@". Next."].location == NSNotFound) {
        NSLog(@"Array name not detected");
    } else {
        // Find and set the array or set name
        NSRange varStartRange = [self.rawInputString rangeOfString:@"Call it " options:NSBackwardsSearch];
        NSRange varEndRange = [self.rawInputString rangeOfString:@". Next.\n" options:NSBackwardsSearch];
        NSUInteger varLength = (varEndRange.location) - (varStartRange.location+8);
        NSString *varName = [self.rawInputString substringWithRange:NSMakeRange(varStartRange.location+8, varLength)];
        
        // Call a method to replace on-screen text with code
        if ([self.lineStart isEqualToString:@"Create an array"]) {
            self.translatedCodeString = [NSString stringWithFormat:@"NSArray *%@ = [[NSArray alloc] init];\n\t", varName];
            [self replaceLineWithTranslatedCodeString];
        } else if ([self.lineStart isEqualToString:@"Create a mutable array"]) {
            self.translatedCodeString = [NSString stringWithFormat:@"NSMutableArray *%@ = [[NSMutableArray alloc] init];\n\t", varName];
            [self replaceLineWithTranslatedCodeString];
        } else if ([self.lineStart isEqualToString:@"Create a set"]) {
            self.translatedCodeString = [NSString stringWithFormat:@"NSSet *%@ = [[NSSet alloc] init];\n\t", varName];
            [self replaceLineWithTranslatedCodeString];
        } else if ([self.lineStart isEqualToString:@"Create a mutable set"]) {
            self.translatedCodeString = [NSString stringWithFormat:@"NSMutableSet *%@ = [[NSMutableSet alloc] init];\n\t", varName];
            [self replaceLineWithTranslatedCodeString];
        }
    }
}

- (void)replaceLineWithTranslatedCodeString
{
    // First we get the user's original input as a range in textStorage, so we can replace it with code.
    NSRange lineRangeStart = [self.rawInputString rangeOfString:self.lineStart options:NSBackwardsSearch];
    NSRange lineRangeEnd = [self.rawInputString rangeOfString:@". Next.\n" options:NSBackwardsSearch];
    NSUInteger lineRangeLength = (lineRangeEnd.location+7) - (lineRangeStart.location);
    NSRange replacementRange = NSMakeRange(lineRangeStart.location, lineRangeLength);
    
    // We store the user's original input in an array in case we need it.
    self.previousInput = [self.rawInputString substringWithRange:replacementRange];
    [self.previousInputArray addObject:self.previousInput];
    
    // Then we replace the text on-screen with valid code and add the code to an array
    // of commands issued so far.
    [self.textView insertText:self.translatedCodeString replacementRange:replacementRange];
    [self.translatedCodeArray addObject:self.translatedCodeString];
}

// Make an undo function to delete the latest translatedCodeString from the screen
// and remove it as lastObject from translatedCodeArray
// If the words "Undo" appear on-screen, set that as lineRangeEnd and delete the whole string
// from self.lineStart to lineRangeEnd, OR from self.translatedCodeString lastObject to lineRangeEnd.

- (void)didClickStopSpeakIt:(id)sender
{
    self.rawInputString = nil;
    self.previousInput = nil;
    self.translatedCodeString = nil;
    self.lineStart = nil;
    [self.onOffSwitch setTitle:@"Start SpeakIt"];
    [self.onOffSwitch setAction:@selector(didClickBeginSpeakIt:)];
    NSLog(@"Stopped SpeakIt");
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
