//
//  ViewController.m
//  CoreML_Resnet50
//
//  Created by tongle on 2017/9/13.
//  Copyright © 2017年 tong. All rights reserved.
//

#import "ViewController.h"
#import <CoreML/CoreML.h>
#import <Vision/Vision.h>
#import "Resnet50.h"

#define viewWidth self.view.frame.size.width
#define viewHeight self.view.frame.size.height

@interface ViewController ()<UIScrollViewDelegate>
@property (nonatomic,strong)UIScrollView * scrollView;
@property (nonatomic,strong)UIPageControl * pageControl;
@property (nonatomic,strong)UIImage * currentImage;
@property (nonatomic,strong)UILabel * resultLable;
@property (nonatomic,strong)UILabel * confidenceLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
  
    [self.view addSubview:self.resultLable];
    [self.view addSubview:self.confidenceLabel];
    [self addScrollViewAndImageView];
    self.currentImage = [UIImage imageNamed:@"1.jpg"];
    [self openResnet50];
    // Do any additional setup after loading the view, typically from a nib.
}
-(void)addScrollViewAndImageView{
    self.scrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 0, viewWidth, 250)];
    self.scrollView.delegate = self;
    self.scrollView.bounces = YES;
    self.scrollView.contentSize = CGSizeMake(5 * viewWidth, 250);
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    [self.view addSubview:self.scrollView];
    
    self.pageControl = [[UIPageControl alloc]init];
    [self.pageControl setCenter:CGPointMake(viewWidth / 2 - 20, 250 - 10)];
    self.pageControl.numberOfPages = 5;
    self.pageControl.pageIndicatorTintColor = [UIColor blackColor];
    self.pageControl.currentPageIndicatorTintColor = [UIColor redColor];
    for (int i = 0; i < 5; i ++) {
        UIImageView * imageView = [[UIImageView alloc]initWithFrame:CGRectMake(i * viewWidth, 0, viewWidth, 250)];
        imageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"%d.jpg",i + 1]];
        [self.scrollView addSubview:imageView];
    }
    
    [self.view addSubview:self.pageControl];
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
     double page = scrollView.contentOffset.x / scrollView.frame.size.width;
     self.pageControl.currentPage = (int)(page + 0.5);
    
    if (scrollView.contentOffset.x > 4 * viewWidth) {
        self.scrollView.contentOffset = CGPointMake(0, 0);
    }else if (scrollView.contentOffset.x < 0){
        self.scrollView.contentOffset = CGPointMake(4 * viewWidth, 0);
    }
}
-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    self.currentImage =[UIImage imageNamed:[NSString stringWithFormat:@"%d.jpg",(int)(self.pageControl.currentPage)]];
    [self openResnet50];
}

-(UILabel *)resultLable{
    if (_resultLable == nil) {
        _resultLable = [[UILabel alloc]initWithFrame:CGRectMake(0, 260, viewWidth, 40)];
        _resultLable.textColor =[UIColor redColor];
        _resultLable.textAlignment = NSTextAlignmentCenter;
    }
    return _resultLable;
}
-(UILabel *)confidenceLabel{
    if (_confidenceLabel == nil) {
        _confidenceLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 300, viewWidth, 40)];
        _confidenceLabel.textColor = [UIColor greenColor];
        _confidenceLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _confidenceLabel;
}
-(void)openResnet50{
    Resnet50 *resnetModel = [[Resnet50 alloc] init];
    UIImage *image = self.currentImage;
    VNCoreMLModel * vnCoreModel = [VNCoreMLModel modelForMLModel:resnetModel.model error:nil];

    VNCoreMLRequest * vnCoreMlRequest = [[VNCoreMLRequest alloc] initWithModel:vnCoreModel completionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {
        CGFloat confidence = 0.0f;
        VNClassificationObservation *tempClassification = nil;
        for (VNClassificationObservation *classification in request.results) {
            if (classification.confidence > confidence) {
                confidence = classification.confidence;
                tempClassification = classification;
            }
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.resultLable.text = [NSString stringWithFormat:@"识别结果:%@",tempClassification.identifier];
            self.confidenceLabel.text = [NSString stringWithFormat:@"匹配率:%@",@(tempClassification.confidence)];
        });
        
    }];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        VNImageRequestHandler *vnImageRequestHandler = [[VNImageRequestHandler alloc] initWithCGImage:image.CGImage options:nil];
        
        NSError *error = nil;
        [vnImageRequestHandler performRequests:@[vnCoreMlRequest] error:&error];
        
        if (error) {
            NSLog(@"%@",error.localizedDescription);
        }
    });
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
