//
//  QZSpeechRecognizer.m
//
//
//  Created by Stephen Hu on 2018/12/6.
//  Copyright © 2018 Stephen Hu. All rights reserved.
//

#import "QZSpeechRecognizer.h"

#define LVRecordFielName @"lvRecord.caf"// 沙盒地址用来保存录音，但是说过说话结束之后就录音就被删除了（只是用来获取音量）
#ifdef DEBUG
#define QZLog(FORMAT, ...) fprintf(stderr, "%s:%d\t%s\n", [[[NSString stringWithUTF8String: __FILE__] lastPathComponent] UTF8String], __LINE__, [[NSString stringWithFormat: FORMAT, ## __VA_ARGS__] UTF8String]);
#else
#define QZLog(FORMAT, ...) nil
#endif

@interface QZSpeechRecognizer ()<SFSpeechRecognizerDelegate,AVAudioRecorderDelegate>
@property(nonatomic,strong)SFSpeechRecognizer * speechRecognizer;
@property(nonatomic,strong)SFSpeechAudioBufferRecognitionRequest * recognitionRequest;
@property(nonatomic,strong)SFSpeechRecognitionTask * recognitionTask;
@property(nonatomic,strong)AVAudioEngine * audioEngine;
/** 标记能不能说话 */
@property(nonatomic, assign) BOOL canSpeach;
/** 定时器 */
@property (nonatomic, strong) NSTimer *timer;
/** 录音文件地址 */
@property (nonatomic, strong) NSURL *recordFileUrl;
/** 播放器对象 */
@property (nonatomic, strong) AVAudioPlayer *player;
@end

@implementation QZSpeechRecognizer

- (void)stopRecord {
    if (self.recorder.isRecording) {
        [self.recorder stop];
        [self.recorder prepareToRecord];
        self.timer.fireDate = [NSDate distantFuture];
        [self destructionRecordingFile]; // 停止录音删除录音文件该项目里不需要录音
    }
}
- (void)startRecord {
    [self stopPlaying];
    if (self.recorder.prepareToRecord) {
        [self.recorder record];
        self.timer.fireDate = [NSDate distantPast];
    } else {
        self.recorder = [self setRecorder];
    }
}
- (void)updateImage {
    
    [self.recorder updateMeters];
    double lowPassResults = pow(2, (0.05 * [self.recorder peakPowerForChannel:0]));
    float result  = 7 * (float)lowPassResults;
    QZLog(@"音量结果？%f", result);
    int no = 0;
    if (result > 0 && result <= 0.65) {
        no = 1;
    } else if (result > 0.65 && result <= 1) {
        no = 2;
    } else if (result > 1 && result <= 1.5) {
        no = 3;
    } else if (result > 1.5 && result <= 2.5) {
        no = 4;
    } else if (result > 2.5 && result <= 3) {
        no = 5;
    } else if (result > 3 && result <= 5) {
        no = 6;
    } else if (result > 5 && result <= 6) {
        no = 7;
    } else if (result > 6) {
        no = 8;
    }
    
    if ([self.delegate respondsToSelector:@selector(speach:didstartSpeach:)]) {
        [self.delegate speach:self didstartSpeach: no];
    }
}
- (AVAudioRecorder *)setRecorder {
    // 真机环境下需要的代码
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *sessionError;
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&sessionError];
    [session setMode:AVAudioSessionModeMeasurement error:nil];
    if(session == nil) {
        QZLog(@"Error creating session: %@", [sessionError description]);
    } else {
        [session setActive:YES error:nil];
    }
    // 1.获取沙盒地址
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *filePath = [path stringByAppendingPathComponent:LVRecordFielName];
    self.recordFileUrl = [NSURL fileURLWithPath:filePath];
    QZLog(@"输出文件地址。。。。%@", filePath);
    
    // 3.设置录音的一些参数
    NSMutableDictionary *setting = [NSMutableDictionary dictionary];
    // 音频格式
    setting[AVFormatIDKey] = @(kAudioFormatAppleIMA4);
    // 录音采样率(Hz) 如：AVSampleRateKey==8000/44100/96000（影响音频的质量）
    setting[AVSampleRateKey] = @(44100);
    // 音频通道数 1 或 2
    setting[AVNumberOfChannelsKey] = @(1);
    // 线性音频的位深度  8、16、24、32
    setting[AVLinearPCMBitDepthKey] = @(8);
    //录音的质量
    setting[AVEncoderAudioQualityKey] = [NSNumber numberWithInt:AVAudioQualityHigh];
    
    AVAudioRecorder *recorder = [[AVAudioRecorder alloc] initWithURL:self.recordFileUrl settings:setting error:NULL];
    recorder.delegate = self;
    recorder.meteringEnabled = YES;
    [recorder prepareToRecord];
    return recorder;
}
- (void)playRecordingFileWithPath:(NSURL *)filePath {
    // 播放时停止录音
    if (self.recorder.isRecording) {
        [self.recorder stop];
    }
    // 正在播放就返回
    if ([self.player isPlaying]) return;
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:filePath error:NULL];
    [self.player play];
}
- (void)stopPlaying {
    if (self.player.isPlaying) {
        [self.player stop];
    }
}
- (void)destructionRecordingFile {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (self.recordFileUrl) {
        [fileManager removeItemAtURL:self.recordFileUrl error:NULL];
    }
}

#pragma mark - AVAudioRecorderDelegate
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    if (flag) {
        QZLog(@"录音成功");
    }
}
- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError * __nullable)error {
    QZLog(@"录音出现了错误 = %@", error);
}

#pragma mark ————— 翻译相关 —————
- (void)begainSpeach {
    [self startRecognition];
}
- (void)endSpeach {
    if ([self.audioEngine isRunning]) {
        [self.audioEngine stop];
        [self.recognitionRequest endAudio];
        [self.audioEngine.inputNode removeTapOnBus:0];
    }
}
- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupSpeach];
        self.recorder = [self setRecorder];
        NSTimer *timer = [NSTimer timerWithTimeInterval:0.2 target:self selector:@selector(updateImage) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
        self.timer = timer;
        self.timer.fireDate = [NSDate distantFuture];
    }
    return self;
}
- (void)setupSpeach {
    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        switch (status) {
            case SFSpeechRecognizerAuthorizationStatusAuthorized:
                self.canSpeach = true;
                QZLog(@"可以语音识别");
                break;
            case SFSpeechRecognizerAuthorizationStatusDenied:
                self.canSpeach = false;
                QZLog(@"用户被拒绝访问语音识别");
                break;
            case SFSpeechRecognizerAuthorizationStatusRestricted:
                self.canSpeach = false;
                QZLog(@"不能在该设备上进行语音识别");
                break;
            case SFSpeechRecognizerAuthorizationStatusNotDetermined:
                self.canSpeach = false;
                QZLog(@"没有授权语音识别");
                break;
            default:
                break;
        }
    }];
    if (self.statusBlock) {
        self.statusBlock(self.canSpeach);
    }
}
- (void)startRecognition {
    if (self.recognitionTask) {
        [self.recognitionTask cancel];
        self.recognitionTask = nil;
    }
    self.recognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    AVAudioInputNode *inputNode = self.audioEngine.inputNode;
    self.recognitionRequest.shouldReportPartialResults = YES;
    //开始识别任务
    self.recognitionTask = [self.speechRecognizer recognitionTaskWithRequest:self.recognitionRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        bool isFinal = NO;
        if (result) {
            isFinal = [result isFinal];
            if (isFinal) {
                NSString *resText = [[result bestTranscription] formattedString]; //语音转文本
                if (self.recognizeResultBlock) {
                    self.recognizeResultBlock(resText);
                }
            }
        }
        if (error || isFinal) {
            [self.audioEngine stop];
            [inputNode removeTapOnBus:0];
            self.recognitionRequest = nil;
            self.recognitionTask = nil;
            self.canSpeach = YES;
        }
        if (self.statusBlock) {
            self.statusBlock(self.canSpeach);
        }
    }];
    AVAudioFormat *recordingFormat = [inputNode outputFormatForBus:0];
    [inputNode removeTapOnBus:0];
    [inputNode installTapOnBus:0 bufferSize:1024 format:recordingFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        [self.recognitionRequest appendAudioPCMBuffer:buffer];
    }];
    [self.audioEngine prepare];
    bool audioEngineBool = [self.audioEngine startAndReturnError:nil];
    QZLog(@"%d",audioEngineBool);
}

#pragma mark ————— SFSpeechRecognizerDelegate —————
- (void)speechRecognizer:(SFSpeechRecognizer *)speechRecognizer availabilityDidChange:(BOOL)available {
    if (available) {
        self.canSpeach = YES;
    } else {
        self.canSpeach = NO;
    }
    if (self.statusBlock) {
        self.statusBlock(self.canSpeach);
    }
}
- (void)dealloc {
    [self.timer invalidate];
    self.timer = nil;
}

#pragma mark ————— 识别本地音频文件 —————
- (void)recognizeLocalAudioFileWithFileName:(nullable NSString *)fileName orWithFileUrl:(nullable NSURL *)fileUrl {
    NSLocale *local = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
    SFSpeechRecognizer *localRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:local];
    NSURL *url;
    if (fileName) {
        url = [[NSBundle mainBundle] URLForResource:fileName withExtension:nil];
        if (!url) return;
    } else if (fileUrl) { url = fileUrl;}
    SFSpeechURLRecognitionRequest *request = [[SFSpeechURLRecognitionRequest alloc] initWithURL:url];
    request.shouldReportPartialResults = NO;
    __weak typeof(self) weakSelf = self;
    [localRecognizer recognitionTaskWithRequest:request resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        if (error) {
            QZLog(@"语音识别解析失败,%@",error);
        } else {
            if (weakSelf.localRecognizeBlock) {
                weakSelf.localRecognizeBlock(result.bestTranscription.formattedString);
            }
        }
    }];
}
#pragma mark ————— getter —————
- (NSTimeInterval)currentTime {
    return self.recorder.currentTime;
}
#pragma mark ————— lazyLoad —————
- (AVAudioEngine *)audioEngine {
    if (!_audioEngine) {
        _audioEngine = [[AVAudioEngine alloc] init];
    }
    return _audioEngine;
}
- (SFSpeechRecognizer *)speechRecognizer {
    if (!_speechRecognizer) {
        NSLocale *local   = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
        _speechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:local];
        _speechRecognizer.delegate = self;
    }
    return _speechRecognizer;
}
@end
