//
//  ViewController.m
//  OpenGL_ES_GLSL_03
//
//  Created by tlab on 2020/8/4.
//  Copyright © 2020 yuanfangzhuye. All rights reserved.
//

#import "ViewController.h"
#import "TlabView.h"

@interface ViewController ()

@property (nonatomic, strong) TlabView *myView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.myView = (TlabView *)self.view;
}


@end
