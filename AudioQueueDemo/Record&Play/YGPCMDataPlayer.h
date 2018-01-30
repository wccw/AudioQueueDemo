//
//  YGPCMDataPlayer.h
//  AudioQueueDemo
//
//  Created by wangyaoguo on 2018/1/30.
//  Copyright © 2018年 lianluo.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YGPCMDataPlayer : NSObject

-(void)play:(void *)pcmData length:(unsigned int)length;
-(void)stop;


@end
