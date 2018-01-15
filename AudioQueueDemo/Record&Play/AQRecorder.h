//
//  AQRecorder.h
//  AudioQueueDemo
//
//  Created by wangyaoguo on 2018/1/12.
//  Copyright © 2018年 lianluo.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol recorderDelegate <NSObject>
-(void)recordData:(NSData *)data;
@end

@interface AQRecorder : NSObject
- (instancetype)initWithDelegate:(id<recorderDelegate>) delegate;
- (void)beganRecorder;
- (void)beganPlayer;
- (void)playerData:(NSData *)data;
@end
