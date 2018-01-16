//
//  ViewController.m
//  AudioQueueDemo
//
//  Created by wangyaoguo on 2018/1/12.
//  Copyright © 2018年 lianluo.com. All rights reserved.
//

#import "ViewController.h"
#import "AQRecorderAndPlayer.h"
#import "AQPlayer.h"
@interface ViewController ()
{
    AQRecorderAndPlayer *aqRecorderPlayer;
    AQPlayer            *aqPlayer;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    aqRecorderPlayer = [[AQRecorderAndPlayer alloc]init];
    aqPlayer = [[AQPlayer alloc]init];
}
- (IBAction)recorderplayerStart:(id)sender {
    [aqRecorderPlayer beganRecorderPlayer];
}

- (IBAction)recorderplayerStop:(id)sender {
    [aqRecorderPlayer stopRecorderPlayer];
}

- (IBAction)recorderStart:(id)sender {
    
}

- (IBAction)recorderStop:(id)sender {
    
}

- (IBAction)playerStart:(id)sender {
    [aqPlayer startPlayerWithData:nil];
}

- (IBAction)playerStop:(id)sender {
    [aqPlayer stopPlayer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
