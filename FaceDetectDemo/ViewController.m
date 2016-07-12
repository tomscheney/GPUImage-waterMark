//
//  ViewController.m
//  FaceDetectDemo
//
//  Created by Cheney on 16/7/5.
//  Copyright © 2016年 Cheney. All rights reserved.
//



#import "ViewController.h"
#import <GPUImage.h>
#import "GPUImageBeautifyFilter.h"
@interface ViewController (){

    GPUImageVideoCamera *videoCamera;
    GPUImageMovieWriter *movieWriter;
    GPUImageBeautifyFilter *beautifyFilter;
    GPUImageView *filterView;
    
    GPUImageAlphaBlendFilter *blendFilter;
    GPUImageOutput<GPUImageInput> *_writefilter;
}
@property (nonatomic,strong)GPUImageUIElement *uiElementInput;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
}

- (void)videoFilter{
    //GPUImageVideoCamera 必须声明为 全局变量或属性，否则开不到视频
    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionFront];
    videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    //画面镜像
    videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    //视图对象
    filterView = [[GPUImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, ScreenWidth, ScreenHeight)];
    
    filterView.center = self.view.center;
    [self.view insertSubview:filterView atIndex:0];
    //过滤器
     beautifyFilter = [[GPUImageBeautifyFilter alloc] init];
    [videoCamera addTarget:beautifyFilter];
    [beautifyFilter addTarget:filterView];
    
    [videoCamera startCameraCapture];
    
    //加水印的过滤器
    blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
    blendFilter.mix = 1.0;
    
    
    //将视频流写到文件
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.m4v"];
    unlink([pathToMovie UTF8String]);
    NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(480.0, 640.0)];

    //添加录制对象
    [beautifyFilter addTarget:movieWriter];
    //添加音频输入
    videoCamera.audioEncodingTarget = movieWriter;
    
    movieWriter.shouldPassthroughAudio = YES;
    
}
- (IBAction)clickRecord:(UIButton*)sender {
    
    
    if (sender.tag == 0) {
        sender.tag = 1;
        
        
//        movieWriter.encodingLiveVideo = YES;
        //调用刻录方法
        [movieWriter startRecording];
        [sender setTitle:@"停止录制" forState:UIControlStateNormal];
    } else {
        sender.tag = 0;
        [sender setTitle:@"开始录制" forState:UIControlStateNormal];
        //滤镜移除输出视频流对象
        [beautifyFilter removeTarget:movieWriter];
        //调用完成刻录方法
        [movieWriter finishRecording];
        //注销音频输入
        videoCamera.audioEncodingTarget = nil;
    
        [blendFilter removeTarget:movieWriter];
    }
    
}

- (IBAction)addWaterMask:(UIButton*)sender {
    
    if (sender.tag == 0) {
        sender.tag = 1;
    
    
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, filterView.frame.size.width,filterView.frame.size.height)];
    contentView.backgroundColor = [UIColor clearColor];
    UIImage *image = [UIImage imageNamed:@"waterMark"];
    UIImageView *ivTemp = [[UIImageView alloc] initWithFrame:CGRectMake(0, 150, image.size.width, image.size.height)];
    ivTemp.image = image;
    ivTemp.tag = 500;
    ivTemp.hidden = NO;
    [contentView addSubview:ivTemp];
    
    if (_uiElementInput) {
        
        [_uiElementInput removeAllTargets];
    }
    if (beautifyFilter) {
        
        [beautifyFilter removeTarget:filterView];
    }
    
    if (!_uiElementInput) {
        _uiElementInput = [[GPUImageUIElement alloc] initWithView:contentView];
    }
    if (blendFilter) {
        [blendFilter removeAllTargets];
    }
    
    [beautifyFilter addTarget:blendFilter];
    [_uiElementInput addTarget:blendFilter];
    [blendFilter addTarget:filterView];
    
    [beautifyFilter removeTarget:movieWriter];
    [blendFilter addTarget:movieWriter];

    
    __weak typeof(self) weakSelf = self;
    [beautifyFilter setFrameProcessingCompletionBlock:^(GPUImageOutput * filter, CMTime frameTime){
        [contentView viewWithTag:500].hidden = NO;
        [weakSelf.uiElementInput update];
    }];
//    _writefilter = blendFilter;
    } else {
        sender.tag = 0;
        [blendFilter removeTarget:filterView];
        [beautifyFilter addTarget:filterView];
        
        [blendFilter removeTarget:movieWriter];
        [beautifyFilter  addTarget:movieWriter];
        
        
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
//    [self DetectFace];
    [self videoFilter];

}



-(void)DetectFace{
    
    UIImage* image = [UIImage imageNamed:@"face"];
    UIImageView *testImage = [[UIImageView alloc] initWithImage: image];
    [testImage setTransform:CGAffineTransformMakeScale(1, -1)];
    [[[UIApplication sharedApplication] delegate].window setTransform:CGAffineTransformMakeScale(1, -1)];
    [testImage setFrame:CGRectMake(0, 0, testImage.image.size.width,testImage.image.size.height)];
    [self.view addSubview:testImage];
    
    CIImage* ciimage = [CIImage imageWithCGImage:image.CGImage];
    NSDictionary* opts = [NSDictionary dictionaryWithObject:
                          CIDetectorAccuracyHigh forKey:CIDetectorAccuracy];
    CIDetector* detector = [CIDetector detectorOfType:CIDetectorTypeFace
                                              context:nil options:opts];
    NSArray* features = [detector featuresInImage:ciimage];
    
    for (CIFaceFeature *faceFeature in features){
        
        CGFloat faceWidth = faceFeature.bounds.size.width;
        
        // create a UIView using the bounds of the face
        UIView* faceView = [[UIView alloc] initWithFrame:faceFeature.bounds];
        
        // add a border around the newly created UIView
        
        faceView.layer.borderWidth = 1;
        faceView.layer.borderColor = [[UIColor redColor] CGColor];
        
        [self.view addSubview:faceView];
        
        if(faceFeature.hasLeftEyePosition)
            
        {
            // create a UIView with a size based on the width of the face
            
            UIView* leftEyeView = [[UIView alloc] initWithFrame:
                                   CGRectMake(faceFeature.leftEyePosition.x-faceWidth*0.15,
                                              faceFeature.leftEyePosition.y-faceWidth*0.15, faceWidth*0.3, faceWidth*0.3)];
            
            // change the background color of the eye view
            [leftEyeView setBackgroundColor:[[UIColor blueColor]
                                             colorWithAlphaComponent:0.3]];
            
            // set the position of the leftEyeView based on the face
            [leftEyeView setCenter:faceFeature.leftEyePosition];
            
            // round the corners
            leftEyeView.layer.cornerRadius = faceWidth*0.15;
            
            // add the view to the window
            [self.view  addSubview:leftEyeView];
            
        }
        
        if(faceFeature.hasRightEyePosition)
            
        {
            // create a UIView with a size based on the width of the face
            UIView* leftEye = [[UIView alloc] initWithFrame:
                               CGRectMake(faceFeature.rightEyePosition.x-faceWidth*0.15,
                                          faceFeature.rightEyePosition.y-faceWidth*0.15, faceWidth*0.3, faceWidth*0.3)];
            
            // change the background color of the eye view
            [leftEye setBackgroundColor:[[UIColor blueColor]
                                         colorWithAlphaComponent:0.3]];
            
            // set the position of the rightEyeView based on the face
            [leftEye setCenter:faceFeature.rightEyePosition];
            
            // round the corners
            leftEye.layer.cornerRadius = faceWidth*0.15;
            
            // add the new view to the window
            [self.view  addSubview:leftEye];
        }
        
        if(faceFeature.hasMouthPosition)
        {
            
            // create a UIView with a size based on the width of the face
            UIView* mouth = [[UIView alloc] initWithFrame:
                             CGRectMake(faceFeature.mouthPosition.x-faceWidth*0.2,
                                        faceFeature.mouthPosition.y-faceWidth*0.2, faceWidth*0.4, faceWidth*0.4)];
            
            // change the background color for the mouth to green  
            [mouth setBackgroundColor:[[UIColor greenColor]  
                                       colorWithAlphaComponent:0.3]];  
            
            // set the position of the mouthView based on the face  
            [mouth setCenter:faceFeature.mouthPosition];  
            
            // round the corners  
            mouth.layer.cornerRadius = faceWidth*0.2;  
            
            // add the new view to the window  
            [self.view  addSubview:mouth];  
        }         
        
    }  
}

@end
