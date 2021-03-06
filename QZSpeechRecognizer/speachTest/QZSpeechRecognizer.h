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
typedef NS_ENUM(NSInteger, QZSpeechRecognizerAuthorizationStatus) {
    QZSpeechRecognizerAuthorizationStatusNotDetermined,  // 没有授权
    QZSpeechRecognizerAuthorizationStatusDenied,         // 用户拒绝
    QZSpeechRecognizerAuthorizationStatusRestricted,     // 不能在此设备上使用
    QZSpeechRecognizerAuthorizationStatusAuthorized,     // 已授权可以使用
};
@class QZSpeechRecognizer;
@protocol QZSpeechRecognizerDelegate <NSObject>
@optional
/** 根据num值来做操作更换音量图片*/
- (void)speach:(QZSpeechRecognizer *)speach didstartSpeach:(int)num;
@end
@interface QZSpeechRecognizer : NSObject
/** 初始化设置回调 */
@property (nonatomic, copy) void(^statusBlock)(BOOL canSpeach);
/** 开始说话回调 */
@property (nonatomic, copy) void(^recognizeResultBlock)(NSString *resaultText,BOOL isFinal);
/** 本地语音识别回调 */
@property (nonatomic, copy) void(^localRecognizeBlock)(NSString *resaultText);
/** 更新图片的代理 */
@property (nonatomic, weak) id<QZSpeechRecognizerDelegate> delegate;
/** 录音对象 */
@property (nonatomic, strong) AVAudioRecorder *recorder;
/** 用来判断事件时间长度*/
@property(nonatomic,assign) NSTimeInterval currentTime;
/** 语音识别权限*/
@property (nonatomic, assign) QZSpeechRecognizerAuthorizationStatus authorizationStatus;
/** 标记能不能语音识别 */
@property(nonatomic, assign) BOOL canSpeach;
/** 标记麦克风权限是否开启 */
@property(nonatomic, assign) BOOL canUseMacphone;

/** 开始说话 */
- (void)begainSpeach;
/** 结束说话 */
- (void)endSpeach;
/** 开始录音 */
- (void)startRecord;
/** 结束录音 */
- (void)stopRecord;
/** 播放录音文件 */
- (void)playRecordingFileWithPath:(NSURL *)filePath;
/** 停止播放录音文件 */
- (void)stopPlaying;
/** 识别本地音频文件 参数传一个即可*/
- (void)recognizeLocalAudioFileWithFileName:(nullable NSString *)fileName orWithFileUrl:(nullable NSURL *)fileUrl;
@end

NS_ASSUME_NONNULL_END
