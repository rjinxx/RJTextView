//
//  ViewController.m
//  RJTextViewDemo
//
//  Created by Rylan on 3/11/15.
//  Copyright (c) 2015 ArcSoft. All rights reserved.
//

#import "ViewController.h"
#import "RJTextView.h"

@interface ViewController ()

@property (nonatomic, strong) RJTextView *textView;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self.view setBackgroundColor:[UIColor darkGrayColor]];
    
    CGRect rect = self.view.frame;
    
    rect.origin.x += 20; rect.size.width -= 40;
    rect.origin.y  = 30; rect.size.height = rect.size.width;

    UIView *bottomView = [[UIView alloc] initWithFrame:rect];
    [bottomView setBackgroundColor:[UIColor lightGrayColor]];
    
    CGFloat minWidth  = bottomView.bounds.size.width /3.f;
    CGFloat minHeight = bottomView.bounds.size.height/3.f;
    
    RJTextView *textView = [[RJTextView alloc] initWithFrame:bottomView.bounds
                                                 defaultText:@"This is Rylan from ArcSoft"
                                                        font:[UIFont systemFontOfSize:14.f]
                                                       color:[UIColor blackColor]
                                                     minSize:CGSizeMake(minWidth, minHeight)];
    
    [self setTextView:textView]; [bottomView addSubview:textView];
    
    UIPanGestureRecognizer *panGes = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                             action:@selector(panAction:)];
    [bottomView addGestureRecognizer:panGes]; [self.view addSubview:bottomView];
}

- (void)panAction:(UIPanGestureRecognizer *)sender
{
    CGPoint translation = [sender translationInView:self.view];
    
    CGPoint viewCenter = self.textView.center;
    
    viewCenter.x = viewCenter.x + translation.x;
    viewCenter.y = viewCenter.y + translation.y;
    
    if (viewCenter.x - self.textView.frame.size.width  / 2. < 0. ||
        viewCenter.x + self.textView.frame.size.width  / 2. > sender.view.frame.size.width)
    {
        viewCenter.x = self.textView.center.x;
    }
    
    if (viewCenter.y - self.textView.frame.size.height / 2. < 0. ||
        viewCenter.y + self.textView.frame.size.height / 2. > sender.view.frame.size.height)
    {
        viewCenter.y = self.textView.center.y;
    }
    
    [self.textView setCenter:viewCenter];
    [sender setTranslation:CGPointZero inView:self.view];
}

- (void)dealloc
{
    self.textView = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
