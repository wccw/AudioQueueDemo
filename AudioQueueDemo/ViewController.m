//
//  ViewController.m
//  AudioQueueDemo
//
//  Created by wangyaoguo on 2018/1/12.
//  Copyright © 2018年 lianluo.com. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

#import "YGAudioFileStream.h"
#import "YGAudioOutputQueue.h"
#import "AQRecorder.h"


@interface ViewController ()<audioFileStreamDelegate>
{
    YGAudioFileStream *stream;
    AQRecorder *recorder;
    YGAudioOutputQueue *outQueue;
    FILE *file;
    UInt64 fileLength;
    
 
}
@end

@implementation ViewController

-(void)audioStreamPacketData:(NSData *)data withDescriptions:(AudioStreamPacketDescription*)packetsDes {
     //[self performSelector:@selector(delayMethod) withObject:nil afterDelay:0];
    [outQueue playWithPackets:data withDescriptions:packetsDes];
}

-(void)audioStreamPacketData:(NSData *)data withDescription:(AudioStreamPacketDescription)packetDes {
    [outQueue playWithPacket:data withDescription:packetDes];
}

-(void)audioStreamReadyProducePacket {
    outQueue = [[YGAudioOutputQueue alloc]initWithFormat:stream.format withBufferSize:stream.bufferSize withMagicCookie:stream.magicCookie];
}

//open file
-(void)openAudioFile {
    //mp3(true) ,m4a(true), flac(ture),wav(false)
    //caf(true) aac(ture)
    NSString *path = [[NSBundle mainBundle]pathForResource:@"PCMSample" ofType:@"pcm"];
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:path];
    fileLength = [[handle availableData]length];
    file = fopen([path UTF8String], "r");
    if (!file) {
        NSLog(@"open file fail");
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    recorder = [[AQRecorder alloc]init];
    //[self openAudioFile];
    //stream = [[YGAudioFileStream alloc]initWithDelegate:self];
}

- (IBAction)recorderplayerStart:(id)sender {
    int length = 3000;
    for (int i = 0; i < fileLength; i = i + length) {
        void *pcmDataBuffer = malloc(length);
        fread(pcmDataBuffer, 1, length, file);
        NSData *audioData = [NSData dataWithBytes:pcmDataBuffer length:length];
        free(pcmDataBuffer);
        [stream parseData:audioData];
    }
}

- (IBAction)recorderplayerStop:(id)sender {
    
}

- (IBAction)recorderStart:(id)sender {
    [recorder startRecorder];
}

- (IBAction)recorderStop:(id)sender {
}

- (IBAction)playerStart:(id)sender {
    //[filePlay startPlay];
    //[pcmPlay startPlay];
}

- (IBAction)playerStop:(id)sender {
    //[filePlay stopPlay];
    //[pcmPlay stopPlay];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 NSString *aacPath = [[NSBundle mainBundle]pathForResource:@"AACSample" ofType:@"aac"];
 filePlay = [[AudioFilePlayer alloc]initWithPath:aacPath];
 
 //NSString *pcmPath = [[NSBundle mainBundle]pathForResource:@"record" ofType:@"pcm"];
 NSString *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
 NSString *pcmPath = [docPath stringByAppendingPathComponent:@"recording.pcm"];
 pcmPlay = [[PCMFilePlayer alloc]initWithPcmFilePath:pcmPath];
 */
@end

