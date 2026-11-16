#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol MediaManagerDelegate <NSObject>
- (void)mediaManagerDidCaptureImage:(UIImage *)image;
- (void)mediaManagerDidFinishRecordingAudio:(NSURL *)audioURL;
@end

@interface MediaManager : NSObject <UIImagePickerControllerDelegate, UINavigationControllerDelegate, AVAudioRecorderDelegate>

@property (nonatomic, weak) id<MediaManagerDelegate> delegate;
@property (nonatomic, readonly) BOOL isRecording;

+ (instancetype)sharedManager;

- (void)presentCameraFromViewController:(UIViewController *)vc;
- (void)presentPhotoLibraryFromViewController:(UIViewController *)vc;

- (BOOL)startRecordingAudio;
- (NSURL *)stopRecordingAudio;

@end

