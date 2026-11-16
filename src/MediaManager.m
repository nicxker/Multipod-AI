#import "MediaManager.h"

@interface MediaManager () {
    AVAudioRecorder *_recorder;
    NSURL *_audioFileURL;
}
@end

@implementation MediaManager

+ (instancetype)sharedManager {
    static MediaManager *inst = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        inst = [[MediaManager alloc] init];
    });
    return inst;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSString *tmpPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"voice_record.m4a"];
        _audioFileURL = [NSURL fileURLWithPath:tmpPath];
    }
    return self;
}

// ── Camera & Photos ───────────────────────────────────────────────────────────
- (void)presentCameraFromViewController:(UIViewController *)vc {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        picker.allowsEditing = NO;
        [vc presentViewController:picker animated:YES completion:nil];
    } else {
        [self presentPhotoLibraryFromViewController:vc];
    }
}

- (void)presentPhotoLibraryFromViewController:(UIViewController *)vc {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        picker.allowsEditing = NO;
        [vc presentViewController:picker animated:YES completion:nil];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *img = info[UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:YES completion:^{
        if (img && [self.delegate respondsToSelector:@selector(mediaManagerDidCaptureImage:)]) {
            [self.delegate mediaManagerDidCaptureImage:img];
        }
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

// ── Audio Recording ───────────────────────────────────────────────────────────
- (BOOL)startRecordingAudio {
    if (_recorder && _recorder.isRecording) {
        [_recorder stop];
    }

    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *err = nil;
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&err];
    [session setActive:YES error:&err];

    NSDictionary *settings = @{
        AVFormatIDKey: @(kAudioFormatMPEG4AAC),
        AVSampleRateKey: @(16000.0),
        AVNumberOfChannelsKey: @(1),
        AVEncoderAudioQualityKey: @(AVAudioQualityMedium)
    };

    _recorder = [[AVAudioRecorder alloc] initWithURL:_audioFileURL settings:settings error:&err];
    _recorder.delegate = self;

    if ([_recorder prepareToRecord]) {
        return [_recorder record];
    }
    return NO;
}

- (NSURL *)stopRecordingAudio {
    if (_recorder && _recorder.isRecording) {
        [_recorder stop];
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setActive:NO error:nil];
        if ([self.delegate respondsToSelector:@selector(mediaManagerDidFinishRecordingAudio:)]) {
            [self.delegate mediaManagerDidFinishRecordingAudio:_audioFileURL];
        }
        return _audioFileURL;
    }
    return nil;
}

- (BOOL)isRecording {
    return _recorder != nil && _recorder.isRecording;
}

@end

