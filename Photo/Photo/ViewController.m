//
//  ViewController.m
//  Photo
//
//

#import "ViewController.h"
#import <PhotosUI/PhotosUI.h>
#import "PhotoViewController.h"

@interface ViewController () <PHPickerViewControllerDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)openCustomPhotoLibrary:(id)sender {
    PhotoViewController *vc = [[PhotoViewController alloc] init];
    [self presentViewController:vc animated:YES completion:nil];
}


- (IBAction)openPhotoLibrary:(id)sender {
    PHPickerConfiguration *config = [[PHPickerConfiguration alloc] init];
    config.selectionLimit = 1;
    config.filter = [PHPickerFilter imagesFilter];
    PHPickerViewController *pickVC = [[PHPickerViewController alloc] initWithConfiguration:config];
    pickVC.delegate = self;
    [self presentViewController:pickVC animated:YES completion:nil];
}

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results {
    if (results == nil || results.count <= 0) {
        NSLog(@"选择照片失败");
    } else {
        PHPickerResult *result = [results firstObject];
        if ([result.itemProvider canLoadObjectOfClass:[UIImage class]]) {
            __weak __typeof(self)weakSelf = self;
            [result.itemProvider loadObjectOfClass:[UIImage class] completionHandler:^(__kindof id<NSItemProviderReading>  _Nullable object, NSError * _Nullable error) {
                if (!error) {
                    UIImage *tmpImage = (UIImage *)object;
                    NSLog(@"选择照片成功");
                } else {
                    NSLog(@"选择照片失败");
                }
            }];
        } else {
            NSLog(@"选择照片失败");
        }
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}


@end
