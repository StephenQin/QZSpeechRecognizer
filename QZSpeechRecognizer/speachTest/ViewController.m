//
//  ViewController.m
//  speachTest
//
//  Created by Stephen Hu on 2018/10/29.
//  Copyright © 2018 Stephen Hu. All rights reserved.
/* 若激发语音的button放在界面的低端会出现TouchDown事件延迟 添加以下代码解决
 - (void)viewDidAppear:(BOOL)animated{
 [super viewDidAppear:animated];
 for (UIGestureRecognizer *gesture in self.view.window.gestureRecognizers) {
 gesture.delaysTouchesBegan = NO;// 解决TouchDown事件延迟
 }}
 */

#import "ViewController.h"
#import "QZSpeechRecognizer.h"
#import "FFMacVoiceView.h"

#define kWeakSelf(type)  __weak typeof(type) weak##type = type;
@interface ViewController ()<QZSpeechRecognizerDelegate>
@property (weak, nonatomic) IBOutlet UIButton *recordingBtn;
@property (weak, nonatomic) IBOutlet UILabel *titleLab;
@property (weak, nonatomic) IBOutlet UITextField *inPutTextField;
@property (nonatomic, strong) QZSpeechRecognizer *mySpeach;
@property (nonatomic, weak) FFMacVoiceView *macView;
@end

@implementation ViewController

#pragma mark ————— QZSpeechRecognizerDelegate —————
- (void)speach:(QZSpeechRecognizer *)speach didstartSpeach:(int)num {
    NSString *imageName = [NSString stringWithFormat:@"mic_%d", num];
    NSLog(@"imgname:%@",imageName);
    self.macView.imgView.image = [UIImage imageNamed:imageName];
}
#pragma mark ————— 事件 —————
- (IBAction)playLocalFile:(UIButton *)sender {
    NSLog(@"点击播放本地语音文件");
    NSURL *fileUrl = [[NSBundle mainBundle] URLForResource:@"录音.m4a" withExtension:nil];
    [self.mySpeach playRecordingFileWithPath:fileUrl];
}
- (IBAction)localFileRecognize:(UIButton *)sender {
    NSLog(@"识别本地语音文件");
    [self.mySpeach recognizeLocalAudioFileWithFileName:@"录音.m4a" orWithFileUrl:nil];
}
- (IBAction)BtnClick:(UIButton *)sender {
    if (self.mySpeach.canUseMacphone) {
        if (self.mySpeach.canSpeach) {
            self.macView.hidden = NO;
            [self.mySpeach begainSpeach];
            [self.recordingBtn setTitle:@"停止说话" forState:UIControlStateNormal];
            [self.mySpeach startRecord];
        } else {
            switch (self.mySpeach.authorizationStatus) {
                case QZSpeechRecognizerAuthorizationStatusNotDetermined:
                case QZSpeechRecognizerAuthorizationStatusDenied:
                    [self alertWithMessage:@"请在iphone的设置中 语音识别Demo 内开启‘语音识别’权限"];
                    break;
                case QZSpeechRecognizerAuthorizationStatusRestricted:
                    [self alertWithMessage:@"该设备不能使用麦克风进行语音识别"];
                default:
                    break;
            }
        }
    } else {
        [self alertWithMessage:@"请在iphone的设置中 语音识别Demo 内开启‘麦克风’权限"];
    }
}
- (IBAction)stopSpeach:(UIButton *)sender {
    NSTimeInterval currentTime = self.mySpeach.currentTime;
    NSLog(@".......%lf", currentTime);
    if (currentTime < 0.3) {
        self.macView.imgView.image = [UIImage imageNamed:@"mic_0"];
        [self alertWithMessage:@"说话时间太短"];
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self.mySpeach endSpeach];
            [self.mySpeach stopRecord];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.macView.hidden = YES;
                self.recordingBtn.enabled = YES;
                [self.recordingBtn setTitle:@"点我说话" forState:UIControlStateNormal];
            });
        });
    } else {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self.mySpeach endSpeach];
            [self.mySpeach stopRecord];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.macView.imgView.image = [UIImage imageNamed:@"mic_0"];
            });
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.macView.hidden = YES;
                self.recordingBtn.enabled = YES;
                [self.recordingBtn setTitle:@"点我说话" forState:UIControlStateNormal];
            });
        });
    }
}

#pragma mark - 弹窗提示
- (void)alertWithMessage:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alert animated:YES completion:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self dismissViewControllerAnimated:YES completion:nil];
        });
    }];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.mySpeach = [QZSpeechRecognizer new];
    self.mySpeach.delegate = self;
    kWeakSelf(self);
    self.mySpeach.statusBlock = ^(BOOL canSpeach) {
        weakself.recordingBtn.enabled = canSpeach;
    };
    self.mySpeach.localRecognizeBlock = ^(NSString * _Nonnull resaultText) {
        weakself.inPutTextField.text = resaultText;
    };
    self.mySpeach.recognizeResultBlock = ^(NSString * _Nonnull resaultText,BOOL isFinal) {
        weakself.inPutTextField.text = resaultText;
    };
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}
- (FFMacVoiceView *)macView {
    if (!_macView) {
        FFMacVoiceView *macView = [FFMacVoiceView new];
        CGFloat centerX = [UIScreen mainScreen].bounds.size.width / 2;
        CGFloat centerY = 130;
        macView.center = CGPointMake(centerX, centerY);
        macView.bounds = CGRectMake(0, 0, 100, 100);
        [self.view addSubview:macView];
        _macView = macView;
    }
    return _macView;
}
@end
