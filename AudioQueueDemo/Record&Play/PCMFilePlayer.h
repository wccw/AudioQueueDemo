//
//  PCMDataPlayer.h
//  AudioQueueDemo
//
//  Created by wangyaoguo on 2018/1/18.
//  Copyright © 2018年 lianluo.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PCMFilePlayer : NSObject

-(instancetype)initWithPcmFilePath:(NSString *)path;
-(void)startPlay;
-(void)stopPlay;

@end
