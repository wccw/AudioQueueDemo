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
#import "AQLocalFilePlay.h"
#import "PCMDataPlayer.h"
@interface ViewController ()
{
    AQRecorder          *aqRecorder;
    AQLocalFilePlay *filePlay;
    PCMDataPlayer *pcmPlay;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    filePlay = [[AQLocalFilePlay alloc]init];
    pcmPlay = [[PCMDataPlayer alloc]init];

}
- (IBAction)recorderplayerStart:(id)sender {
    [pcmPlay startPlay];
}

- (IBAction)recorderplayerStop:(id)sender {
    [pcmPlay stopPlay];
}

- (IBAction)recorderStart:(id)sender {
    
}

- (IBAction)recorderStop:(id)sender {
}

- (IBAction)playerStart:(id)sender {
    [filePlay startPlay];
    //[aqPlayer startPlay];
}

- (IBAction)playerStop:(id)sender {
    [filePlay stopPlay];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
