//
//  macVoiceView.m
//  speachTest
//
//  Created by Stephen Hu on 2018/10/31.
//  Copyright © 2018 Stephen Hu. All rights reserved.
//

#import "FFMacVoiceView.h"

@implementation FFMacVoiceView


#pragma mark ————— 基础设置 —————
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self makeupUI];
    }
    return self;
}
- (void)makeupUI {
    UIImageView *imgView = [[UIImageView alloc] init];
    imgView.image = [UIImage imageNamed:@"mic_0"];
    imgView.frame = CGRectMake(0, 0, 100, 100);
    [self addSubview:imgView];
    self.imgView = imgView;
}
@end
