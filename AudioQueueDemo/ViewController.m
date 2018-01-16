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
@interface ViewController ()
{
    AQRecorderAndPlayer *aqRecorderPlayer;
    AQRecorder          *aqRecorder;
    AQPlayer            *aqPlayer;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //Do any additional setup after loading the view, typically from a nib.
    BOOL success = [[AVAudioSession sharedInstance]setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    if (!success) {
        NSLog(@"Audio Session Failed");
        return;
    }
    aqRecorder = [[AQRecorder alloc]init];
   
}
- (IBAction)recorderplayerStart:(id)sender {
    [aqRecorderPlayer beganRecorderPlayer];
}

- (IBAction)recorderplayerStop:(id)sender {
    [aqRecorderPlayer stopRecorderPlayer];
}

- (IBAction)recorderStart:(id)sender {
    [aqRecorder startRecorder];
}

- (IBAction)recorderStop:(id)sender {
    [aqRecorder stopRecorder];
}

- (IBAction)playerStart:(id)sender {
    
}

- (IBAction)playerStop:(id)sender {
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
