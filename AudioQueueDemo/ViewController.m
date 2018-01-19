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
#import "PCMFilePlayer.h"
#import "AudioFilePlayer.h"
@interface ViewController ()
{
    AQRecorder    *record;
    PCMFilePlayer *pcmPlay;
    AudioFilePlayer *filePlay;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    record = [[AQRecorder alloc]init];
    
    NSString *aacPath = [[NSBundle mainBundle]pathForResource:@"AACSample" ofType:@"aac"];
    filePlay = [[AudioFilePlayer alloc]initWithPath:aacPath];
    
    //NSString *pcmPath = [[NSBundle mainBundle]pathForResource:@"record" ofType:@"pcm"];
    NSString *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *pcmPath = [docPath stringByAppendingPathComponent:@"recording.pcm"];
    pcmPlay = [[PCMFilePlayer alloc]initWithPcmFilePath:pcmPath];
}
- (IBAction)recorderplayerStart:(id)sender {
    //[pcmPlay startPlay];
}

- (IBAction)recorderplayerStop:(id)sender {
    //[pcmPlay stopPlay];
}

- (IBAction)recorderStart:(id)sender {
    [record startRecorder];
}

- (IBAction)recorderStop:(id)sender {
    [record stopRecorder];
}

- (IBAction)playerStart:(id)sender {
    //[filePlay startPlay];
    [pcmPlay startPlay];
}

- (IBAction)playerStop:(id)sender {
    //[filePlay stopPlay];
    [pcmPlay stopPlay];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
