//
//  ViewController.m
//  AudioQueueDemo
//
//  Created by wangyaoguo on 2018/1/12.
//  Copyright © 2018年 lianluo.com. All rights reserved.
//

#import "ViewController.h"
#import "AQRecorder.h"
#import "AQPlayer.h"
@interface ViewController () <recorderDelegate>
{
    AQRecorder *recorder;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    recorder = [[AQRecorder alloc]initWithDelegate:self];
    [recorder beganRecorder];
    [recorder beganPlayer];
}

-(void)recordData:(NSData *)data {
    [recorder playerData:data];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
