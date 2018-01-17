//
//  ViewController.m
//  AudioQueueDemo
//
//  Created by wangyaoguo on 2018/1/12.
//  Copyright © 2018年 lianluo.com. All rights reserved.
//

#import "ViewController.h"
#import "AQRecorderAndPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import "AQPlayer.h"
#import "AQRecorder.h"
#import "YGAudioFile.h"
@interface ViewController ()
{
    //AQRecorderAndPlayer *aqRecorderPlayer;
    //AQRecorder          *aqRecorder;
    //AQPlayer            *aqPlayer;
    YGAudioFile         *audioFile;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //Do any additional setup after loading the view, typically from a nib.
//    BOOL success = [[AVAudioSession sharedInstance]setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
//    if (!success) {
//        NSLog(@"Audio Session Failed");
//        return;
//    }
//    aqRecorder = [[AQRecorder alloc]init];
//    aqPlayer = [[AQPlayer alloc]init];
    NSString *path = [[NSBundle mainBundle]pathForResource:@"MP3Sample" ofType:@"mp3"];
    audioFile = [[YGAudioFile alloc]initWithFilePath:path withFileID:kAudioFormatMPEGLayer3];
   
}
- (IBAction)recorderplayerStart:(id)sender {
    //[aqRecorderPlayer beganRecorderPlayer];
}

- (IBAction)recorderplayerStop:(id)sender {
    //[aqRecorderPlayer stopRecorderPlayer];
}

- (IBAction)recorderStart:(id)sender {
    //[aqRecorder startRecorder];
}

- (IBAction)recorderStop:(id)sender {
    //[aqRecorder stopRecorder];
}

- (IBAction)playerStart:(id)sender {
    //[aqPlayer startPlay];
}

- (IBAction)playerStop:(id)sender {
    //[aqPlayer stopPlay];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
