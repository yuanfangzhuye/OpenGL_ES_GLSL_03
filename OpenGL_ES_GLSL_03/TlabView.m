//
//  TlabView.m
//  OpenGL_ES_GLSL_03
//
//  Created by tlab on 2020/8/4.
//  Copyright © 2020 yuanfangzhuye. All rights reserved.
//

#import "TlabView.h"
#import "GLESMath.h"
#import "GLESUtils.h"
#import <OpenGLES/ES2/gl.h>

@interface TlabView ()

@property (nonatomic, strong) CAEAGLLayer *myLayer;
@property (nonatomic, strong) EAGLContext *myContext;

@property (nonatomic, assign) GLuint myRenderBuffer;
@property (nonatomic, assign) GLuint myFrameBuffer;

@property (nonatomic, assign) GLuint myProgram;
@property (nonatomic, assign) GLuint myVertices;

@end

@implementation TlabView
{
    float xDegree;
    float yDegree;
    float zDegree;
    BOOL bX;
    BOOL bY;
    BOOL bZ;
    NSTimer* myTimer;
}

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

- (void)layoutSubviews
{
    //1.设置图层
    [self setupLayer];
    
    //2.设置上下文
    [self setupContext];
    
    //3.清空缓存区
    [self deleteBuffer];
    
    //4.设置renderBuffer
    [self setupRenderBuffer];
    
    //5.设置frameBuffer
    [self setupFrameBuffer];
    
    //6.绘制
    [self startRender];
}

- (void)setupLayer
{
    self.myLayer = (CAEAGLLayer *)self.layer;
    [self setContentScaleFactor:[[UIScreen mainScreen] scale]];
    self.myLayer.opaque = YES;
    self.myLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
}

- (void)setupContext
{
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!context) {
        NSLog(@"Create Context Failed");
        return;
    }
    if (![EAGLContext setCurrentContext:context]) {
        NSLog(@"Set Current Context Failed");
        return;
    }
    
    self.myContext = context;
}

- (void)deleteBuffer
{
    glDeleteBuffers(1, &_myRenderBuffer);
    _myRenderBuffer = 0;
    
    glDeleteBuffers(1, &_myFrameBuffer);
    _myFrameBuffer = 0;
}

- (void)setupRenderBuffer
{
    //1.定义一个缓存区
    GLuint buffer;
    
    //2.申请一个缓存区标志
    glGenRenderbuffers(1, &buffer);
    
    //3.
    self.myRenderBuffer = buffer;
    
    //4.将标识符绑定到GL_RENDERBUFFER
    glBindRenderbuffer(GL_RENDERBUFFER, self.myRenderBuffer);
    [self.myContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myLayer];
}

- (void)setupFrameBuffer
{
    //1.定义一个缓存区
    GLuint buffer;
    
    //2.申请一个缓存区标志
    glGenFramebuffers(1, &buffer);
    
    //3.
    self.myFrameBuffer = buffer;
    
    //4.设置当前的framebuffer
    glBindFramebuffer(GL_FRAMEBUFFER, self.myFrameBuffer);
    
    //5.将myRenderBuffer 装配到GL_COLOR_ATTACHMENT0 附着点上
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.myRenderBuffer);
}

- (void)startRender
{
    [self setupRC];
    [self setupProgram];
    [self setupVertexdatas];
}

- (void)setupRC
{
    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    
    CGFloat scale = [[UIScreen mainScreen] scale];
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale);
}

- (void)setupProgram
{
    // 顶点着色器/片元着色器
    NSString *vertFile = [[NSBundle mainBundle] pathForResource:@"shaderv" ofType:@"glsl"];
    NSString *fragFile = [[NSBundle mainBundle] pathForResource:@"shaderf" ofType:@"glsl"];
    
    if (self.myProgram) {
        glDeleteProgram(self.myProgram);
        self.myProgram = 0;
    }
    
    self.myProgram = [self loadShader:vertFile frag:fragFile];
    
    glLinkProgram(self.myProgram);
    
    GLint linkStatus;
    
    // 获取链接状态
    glGetProgramiv(self.myProgram, GL_LINK_STATUS, &linkStatus);
    if (linkStatus == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(self.myProgram, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        
        NSLog(@"error%@", messageString);
        return;
    }
    else {
        glUseProgram(self.myProgram);
    }
}

- (void)setupVertexdatas
{
    //1. 顶点数组.索引数组;
    //(1)顶点数组 前3顶点值（x,y,z），后3位颜色值(RGB)
    GLfloat attrArray[] = {
        -0.5f, 0.5f, 0.0f,      0.0f, 0.0f, 0.5f,       0.0f, 1.0f,//左上
        0.5f, 0.5f, 0.0f,       0.0f, 0.5f, 0.0f,       1.0f, 1.0f,//右上
        -0.5f, -0.5f, 0.0f,     0.5f, 0.0f, 1.0f,       0.0f, 0.0f,//左下
        0.5f, -0.5f, 0.0f,      0.0f, 0.0f, 0.5f,       1.0f, 0.0f,//右下
        0.0f, 0.0f, 1.0f,       1.0f, 1.0f, 1.0f,       0.5f, 0.5f,//顶点
    };
    
    //(2)索引数组
    GLuint indices[] = {
        0, 3, 2,
        0, 1, 3,
        0, 2, 4,
        0, 4, 1,
        2, 3, 4,
        1, 4, 3,
    };
    
    if (self.myVertices == 0) {
        glGenBuffers(1, &_myVertices);
    }
    
    glBindBuffer(GL_ARRAY_BUFFER, _myVertices);
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArray), attrArray, GL_DYNAMIC_DRAW);
    
    GLuint position = glGetAttribLocation(self.myProgram, "position");
    glEnableVertexAttribArray(position);
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 8, (GLfloat *)NULL);
    
    GLuint positionColor = glGetAttribLocation(self.myProgram, "positionColor");
    glEnableVertexAttribArray(positionColor);
    glVertexAttribPointer(positionColor, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 8, (GLfloat *)NULL + 3);
    
    GLuint textCoor = glGetAttribLocation(self.myProgram, "textCoor");
    glEnableVertexAttribArray(textCoor);
    glVertexAttribPointer(textCoor, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 8, (GLfloat *)NULL + 6);
    
    //加载纹理;-> 纹理解压
    [self setupTexture];
    
    glUniform1i(glGetUniformLocation(self.myProgram, "colorMap"), 0);
    
    //mvp
    GLuint projectionMatrixSlot = glGetUniformLocation(self.myProgram, "projectionMatrix");
    GLuint modelViewMatrixSlot = glGetUniformLocation(self.myProgram, "modelViewMatrix");
    
    float width = self.frame.size.width;
    float height = self.frame.size.height;
    float aspect = fabs(width/height);
    
    //4*4 投影矩阵
    KSMatrix4 _projectionMatrix;
    ksMatrixLoadIdentity(&_projectionMatrix);
    ksPerspective(&_projectionMatrix, 30.0f, aspect, 5.0f, 20.0f);
    glUniformMatrix4fv(projectionMatrixSlot, 1, GL_FALSE, (GLfloat *)&_projectionMatrix.m[0][0]);
    
    //4*4 模型视图矩阵
    KSMatrix4 _modelViewMatrix;
    ksMatrixLoadIdentity(&_modelViewMatrix);
    ksTranslate(&_modelViewMatrix, 0, 0, -10.0f);
    
    KSMatrix4 _rotationMatrix;
    ksMatrixLoadIdentity(&_rotationMatrix);
    //XYZ
    ksRotate(&_rotationMatrix, xDegree, 1.0, 0, 0);
    ksRotate(&_rotationMatrix, yDegree, 0, 1.0, 0);
    ksRotate(&_rotationMatrix, zDegree, 0, 0, 1.0);
    
    //矩阵相乘
    ksMatrixMultiply(&_modelViewMatrix, &_rotationMatrix, &_modelViewMatrix);
    glUniformMatrix4fv(modelViewMatrixSlot, 1, GL_FALSE, (GLfloat *)&_modelViewMatrix.m[0][0]);
    
    glEnable(GL_CULL_FACE);
    
    //15.使用索引绘图
    /**
     void glDrawElements(GLenum mode,GLsizei count,GLenum type,const GLvoid * indices);
     参数列表：
     mode:要呈现的画图的模型
     GL_POINTS
     GL_LINES
     GL_LINE_LOOP
     GL_LINE_STRIP
     GL_TRIANGLES
     GL_TRIANGLE_STRIP
     GL_TRIANGLE_FAN
     count:绘图个数
     type:类型
     GL_BYTE
     GL_UNSIGNED_BYTE
     GL_SHORT
     GL_UNSIGNED_SHORT
     GL_INT
     GL_UNSIGNED_INT
     indices：绘制索引数组
     */
    glDrawElements(GL_TRIANGLES, sizeof(indices) / sizeof(indices[0]), GL_UNSIGNED_INT, indices);
    [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
}

//从图片中加载纹理
- (GLuint)setupTexture
{
    //1、将 UIImage 转换为 CGImageRef
    CGImageRef spriteImage = [UIImage imageNamed:@"timg.png"].CGImage;
    if (!spriteImage) {
        NSLog(@"Failed to load image");
        exit(1);
    }
    
    //2、读取图片的大小，宽和高
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    //3.读取图片字节数 宽*高*4（RGBA）
    GLubyte *spriteData = (GLubyte *)calloc(width * height * 4, sizeof(GLubyte));
    
    //4.创建上下文
    /**
     参数1：data,指向要渲染的绘制图像的内存地址
     参数2：width,bitmap的宽度，单位为像素
     参数3：height,bitmap的高度，单位为像素
     参数4：bitPerComponent,内存中像素的每个组件的位数，比如32位RGBA，就设置为8
     参数5：bytesPerRow,bitmap的没一行的内存所占的比特数
     参数6：colorSpace,bitmap上使用的颜色空间  kCGImageAlphaPremultipliedLast：RGBA
     */
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4,CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    
    //5、在CGContextRef上--> 将图片绘制出来
    /*
     CGContextDrawImage 使用的是Core Graphics框架，坐标系与UIKit 不一样。UIKit框架的原点在屏幕的左上角，Core Graphics框架的原点在屏幕的左下角。
     CGContextDrawImage
     参数1：绘图上下文
     参数2：rect坐标
     参数3：绘制的图片
     */
    CGRect rect = CGRectMake(0, 0, width, height);
    
    //6.使用默认方式绘制
    CGContextDrawImage(spriteContext, rect, spriteImage);
    
    //7、画图完毕就释放上下文
    CGContextRelease(spriteContext);
    
    //8、绑定纹理到默认的纹理ID
    glBindTexture(GL_TEXTURE_2D, 0);
    
    //9.设置纹理属性
    /*
     参数1：纹理维度
     参数2：线性过滤、为s,t坐标设置模式
     参数3：wrapMode,环绕模式
     */
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    float fw = width, fh = height;
    
    //10.载入纹理2D数据
    /**
     参数1：纹理模式，GL_TEXTURE_1D、GL_TEXTURE_2D、GL_TEXTURE_3D
     参数2：加载的层次，一般设置为0
     参数3：纹理的颜色值GL_RGBA
     参数4：宽
     参数5：高
     参数6：border，边界宽度
     参数7：format
     参数8：type
     参数9：纹理数据
     */
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, fw, fh, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    //11.释放spriteData
    free(spriteData);
    return 0;
}

#pragma mark ------ shader

- (GLuint)loadShader:(NSString *)vert frag:(NSString *)frag
{
    GLuint vertShader, fragShader;
    GLuint program = glCreateProgram();
    
    [self compileShader:&vertShader type:GL_VERTEX_SHADER file:vert];
    [self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:frag];
    
    glAttachShader(program, vertShader);
    glAttachShader(program, fragShader);
    
    glDeleteShader(vertShader);
    glDeleteShader(fragShader);
    
    return program;
}

- (void)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    //读取文件路径字符串
    NSString *content = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    
    //获取文件路径字符串，C语言字符串
    const GLchar *source = (GLchar *)[content UTF8String];
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    
    glCompileShader(*shader);
}

- (IBAction)xClick:(id)sender {
    if (!myTimer) {
        myTimer = [NSTimer scheduledTimerWithTimeInterval:0.05f target:self selector:@selector(reDegree) userInfo:nil repeats:YES];
    }
    
    bX = !bX;
}

- (IBAction)yClick:(id)sender {
    if (!myTimer) {
        myTimer = [NSTimer scheduledTimerWithTimeInterval:0.05f target:self selector:@selector(reDegree) userInfo:nil repeats:YES];
    }
    
    bY = !bY;
}

- (IBAction)zClick:(id)sender {
    if (!myTimer) {
        myTimer = [NSTimer scheduledTimerWithTimeInterval:0.05f target:self selector:@selector(reDegree) userInfo:nil repeats:YES];
    }
    
    bZ = !bZ;
}

- (void)reDegree
{
    xDegree += bX * 5;
    yDegree += bY * 5;
    zDegree += bZ * 5;
    
    [self startRender];
}

@end
