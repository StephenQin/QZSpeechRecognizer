//
//  QZSpeechRecognizer.h
//
//
//  Created by Stephen Hu on 2018/12/6.
//  Copyright © 2018 Stephen Hu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <Speech/Speech.h>

NS_ASSUME_NONNULL_BEGIN
@class QZSpeechRecognizer;
@protocol QZSpeechRecognizerDelegate <NSObject>
@optional
/** 根据num值来做操作更换音量图片*/
- (void)speach:(QZSpeechRecognizer *)speach didstartSpeach:(int)num;
@end
@interface QZSpeechRecognizer : NSObject
/** 初始化设置回调 */
@property (nonatomic, copy) void(^setBlock)(BOOL canSpeach);
/** 开始说话回调 */
@property (nonatomic, copy) void(^begainBlock)(NSString *resaultText);
/** 本地语音识别回调 */
@property (nonatomic, copy) void(^localRecBlock)(NSString *resaultText);
/** 更新图片的代理 */
@property (nonatomic, weak) id<QZSpeechRecognizerDelegate> delegate;
/** 录音对象 */
@property (nonatomic, strong) AVAudioRecorder *recorder;
/** 开始说话 */
- (void)begainSpeach;
/** 结束说话 */
- (void)endSpeach;
/** 开始录音 */
- (void)startRecord;
/** 结束录音 */
- (void)stopRecord;
/** 播放录音文件 */
- (void)playRecordingFile;
/** 停止播放录音文件 */
- (void)stopPlaying;
/** 识别本地音频文件 参数传一个即可*/
- (void)recognizeLocalAudioFileWithFileName:(nullable NSString *)fileName orWithFileUrl:(nullable NSURL *)fileUrl;
@end

NS_ASSUME_NONNULL_END
