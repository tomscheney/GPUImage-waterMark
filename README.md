#GPUImage-waterMark

完美解决GPUImage加水印的需求，在视频录制的任意时刻加自定义水印，修改水印，移除水印。
一、开启实时视频
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
    
    [videoCamera startCameraCapture];/*到此开启视频*/
    
    /*为加水印初始化对象*/
    //加水印的过滤器
    blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
    blendFilter.mix = 1.0;
    
    /*为录制初始化对象*/
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
二、录制视频
- (IBAction)clickRecord:(UIButton*)sender {
    
    
    if (sender.tag == 0) {
        sender.tag = 1;
        
        /*开启这个方法，......*/
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
        /*水印过滤器移除录制对象*/
        [blendFilter removeTarget:movieWriter];
    }
    
}
三、加上水印
- (IBAction)addWaterMask:(UIButton*)sender {
    
    if (sender.tag == 0) {
        sender.tag = 1;
    
    /*初始化水印视图*/
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

    /*一定要把beautyFilter的视频流对象movieWriter移除，在赋值给水印过滤器blendFilter*/
    [beautifyFilter removeTarget:movieWriter];
    [blendFilter addTarget:movieWriter];

    
    __weak typeof(self) weakSelf = self;
    [beautifyFilter setFrameProcessingCompletionBlock:^(GPUImageOutput * filter, CMTime frameTime){
       // [contentView viewWithTag:500].hidden = NO;
        [weakSelf.uiElementInput update];/*一定要调用 GPUImageUIElement 对象的update，对每一帧图片加水印处理*/
    }];
//    _writefilter = blendFilter;/*这里是借鉴了别人的，加上好像没什么用*/
    } else {
        sender.tag = 0;
        /*显示视图的切换*/
        [blendFilter removeTarget:filterView];
        [beautifyFilter addTarget:filterView];
        /*视频流对象切换*/
        [blendFilter removeTarget:movieWriter];
        [beautifyFilter  addTarget:movieWriter];
        
        
    }
}

有兴趣的同学可以继续研究水印动画、
