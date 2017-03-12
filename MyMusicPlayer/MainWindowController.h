//
//  MainWindowController.h
//  MyMusicPlayer
//
//  Created by isaced on 13-7-21.
//  Copyright (c) 2013年 isaced. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MainWindowController : NSWindowController<NSTableViewDataSource>

- (IBAction)previousAction:(id)sender;
- (IBAction)nextAction:(id)sender;
- (IBAction)playAction:(id)sender;

@property (weak) IBOutlet NSTextField *TitleTextField;

@end
