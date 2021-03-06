//
//  MainWindowController.m
//  MyMusicPlayer
//
//  Created by isaced on 13-7-21.
//  Copyright (c) 2013年 isaced. All rights reserved.
//

#import "MainWindowController.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "Music.h"

@interface MainWindowController () <NSDraggingDestination>

@property (weak) IBOutlet NSImageView *backgroundImageView;
@property (weak) IBOutlet NSSlider *progressSlider;
@property (weak) IBOutlet NSButton *playButton;
@property (weak) IBOutlet NSImageView *dragImageView;

@property (strong) NSTimer *playingTimer;
@property (strong) AVAudioPlayer* player;
@property (strong) NSMutableArray<Music *> *musicList;

@end

@implementation MainWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Title Bar
    self.window.titlebarAppearsTransparent = YES;
    self.window.titleVisibility = NSWindowTitleHidden;
    self.window.styleMask |= NSFullSizeContentViewWindowMask;
    
    // Window Style
    NSColor *windowBackgroundColor = [NSColor colorWithRed:30/255.0 green:30/255.0 blue:30/255.0 alpha:1.0];
    [self.window setBackgroundColor: windowBackgroundColor];
    self.window.movableByWindowBackground = YES;
    
    // Drag and drop
    [self.window registerForDraggedTypes:@[NSFilenamesPboardType]];
    [self.backgroundImageView unregisterDraggedTypes];
    
    // init Array
    self.musicList = [[NSMutableArray alloc] init];
    
    // default volume
    [self.player setVolume: 0.5];
    
    self.playingTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(playingTimerHandle:) userInfo:nil repeats:YES];
    
    // KVO AVAudioPlayer playing status
    [self.player addObserver:self forKeyPath:@"playing" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
}

- (Music *)loadMusicWithFileURL:(NSURL *)url {
    [self.player stop];
    
    // 从文件读取音频信息
    Music *music = [[Music alloc] initWithFile:url];
    
    // 将音乐加载到 AVAudioPlayer
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:music.fileURL error:nil];
    
    return music;
}

- (void)playingTimerHandle:(NSTimer *)timer {
    self.progressSlider.doubleValue = self.player.currentTime / self.player.duration;
}

// 上一首
- (IBAction)previousAction:(id)sender {

}

// 下一首
- (IBAction)nextAction:(id)sender {
    
}

// 播放 & 暂停
- (IBAction)playAction:(id)sender {
    if (self.player.url) {
        if (self.player.playing) {
            [self.player pause];
        }else{
            [self.player play];
        }
    }else{
        [self openMusicWithDialog];
    }
    
    [self.playButton setImage:[NSImage imageNamed:self.player.playing ? @"pause" : @"play"]];
}
- (IBAction)progressSliderAction:(NSSlider *)sender {
    NSTimeInterval time = self.progressSlider.doubleValue * self.player.duration;
    self.player.currentTime = time;
}


- (void)openMusicWithDialog {
    
    //初始化 NSOpenPanel
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    
    //只能选择文件
    [openDlg setCanChooseFiles:YES];
    [openDlg setCanChooseDirectories:NO];
    
    //允许多选
    [openDlg setAllowsMultipleSelection:NO];
    
    NSArray *urlArray;
    
    //打开
    if ([openDlg runModal] == NSOKButton) {
        urlArray = [openDlg URLs];
    }
    
    //分析
    for (NSURL *url in urlArray) {
        [self loadMusicWithFileURL:url];
        [self.player play];
        return;
    }
}

//音量调节 - Slider
- (IBAction)soundVolumeSliderChangeAction:(id)sender {
    NSSlider *slider = (NSSlider *)sender;
    [self.player setVolume:slider.doubleValue];
}
    
//Tableview
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];

    Music *music = self.musicList[row];

    if( [tableColumn.identifier isEqualToString:@"number"] ){
        cellView.textField.stringValue = [NSString stringWithFormat:@"%ld",row];
    }else if ([tableColumn.identifier isEqualToString:@"name"]){
        cellView.textField.stringValue = music.title;
    }else if ([tableColumn.identifier isEqualToString:@"time"]){
        cellView.textField.stringValue = [NSString stringWithFormat:@"%d:%.2d",(int)music.duration / 60, (int)music.duration % 60];
    }
    
    return cellView;
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [self.musicList count];
}

#pragma mark <NSDraggingDestination>

-(NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender{
    self.dragImageView.hidden = NO;
    return NSDragOperationGeneric;
}

-(void)draggingExited:(id<NSDraggingInfo>)sender{
    self.dragImageView.hidden = YES;
}

-(BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender{
    BOOL canAccept = NO;
    NSPasteboard *pasteBoard = [sender draggingPasteboard];
    if ([pasteBoard canReadObjectForClasses:@[[NSURL class]] options:nil]) {
        NSArray *urls = [pasteBoard readObjectsForClasses:@[[NSURL class]] options:nil];
        for (NSURL *url in urls) {
            if ([[url pathExtension] isEqualToString:@"mp3"]) { // type check
                canAccept = YES;
                break;
            }
        }
    }
    
    self.dragImageView.hidden = YES;
    return canAccept;
}

-(BOOL)performDragOperation:(id<NSDraggingInfo>)sender{
    NSPasteboard *pasteBoard = [sender draggingPasteboard];
    NSArray *urls = [pasteBoard readObjectsForClasses:@[[NSURL class]] options:nil];
    NSLog(@"Drag and drop : %@",urls);
    
    NSURL *url = [urls firstObject];
    if ([[url pathExtension] isEqualToString:@"mp3"]) {
        Music *music = [self loadMusicWithFileURL:url];
        self.TitleTextField.stringValue = [NSString stringWithFormat:@"%@ - %@",music.title,music.artist];
        [self.player play];
    }
    
    return YES;
}

@end
