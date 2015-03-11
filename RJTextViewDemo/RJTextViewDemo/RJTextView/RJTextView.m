//
//  RJTextView.m
//  RJTextViewDemo
//
//  Created by Rylan on 3/11/15.
//  Copyright (c) 2015 ArcSoft. All rights reserved.
//

#import "RJTextView.h"

#define TEST_CENTER_ALIGNMENT   0
#define PEN_ICON_SIZE           26.5
#define EDIT_BOX_LINE           3.0
#define MAX_FONT_SIZE           500
#define MAX_TEXT_LETH           50

#define IS_IOS_7 ([[UIDevice currentDevice].systemVersion floatValue] >= 7.0f)

@implementation CTextView

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if ( action == @selector(paste:)     ||
         action == @selector(cut:)       ||
         action == @selector(copy:)      ||
         action == @selector(select:)    ||
         action == @selector(selectAll:) ||
         action == @selector(delete:) )
    {
        return NO;
    }
    return [super canPerformAction:action withSender:sender];
}

@end

@interface RJTextView () <UITextViewDelegate>
{
    BOOL _isDeleting;
}
@property (assign, nonatomic) BOOL        isEditting;
@property (assign, nonatomic) BOOL        hideView;
@property (retain, nonatomic) CTextView   *textView;
@property (retain, nonatomic) UIButton    *editButton;
@property (retain, nonatomic) UIImageView *indicatorView;
@property (retain, nonatomic) UIImageView *scaleView;
@property (retain, nonatomic) UIColor     *tColor;
@property (assign, nonatomic) CGPoint     textCenter;
@property (assign, nonatomic) CGSize      minSize;
@property (assign, nonatomic) CGFloat     minFontSize;
@property (retain, nonatomic) UIFont      *curFont;

@end

@implementation RJTextView

- (id)initWithFrame:(CGRect)frame
        defaultText:(NSString *)text
               font:(UIFont *)font
              color:(UIColor *)color
            minSize:(CGSize)minSize
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Custom initialization
        BOOL sExtend = frame.size.height <=0 || frame.size.width <=0;
        BOOL oExtend = frame.origin.x    < 0 || frame.origin.y   < 0;
        
        if (sExtend || oExtend /*|| ![text length]*/) return nil;
        
        [self setBackgroundColor:[UIColor clearColor]];
        self.tColor = color; self.curFont = font; self.minFontSize = font.pointSize;
        [self createTextViewWithFrame:CGRectZero text:nil font:nil];

        UIButton *editButton = [[UIButton alloc] initWithFrame:CGRectZero];
        [editButton setBackgroundImage:[UIImage imageNamed:@"pe_pen_icon"]
                              forState:UIControlStateNormal];
        [editButton setBackgroundImage:[UIImage imageNamed:@"pe_pen_icon_push"]
                              forState:UIControlStateHighlighted];
        [editButton addTarget:self action:@selector(editTextView)
             forControlEvents:UIControlEventTouchUpInside];
        [editButton setExclusiveTouch:YES]; [self addSubview:editButton];
        [self setEditButton:editButton]; [editButton release];
        
        UIImageView *sView = [[UIImageView alloc] initWithFrame:CGRectZero];
        [sView setImage:[UIImage imageNamed:@"pe_pen_scale"]];
        [sView setHighlightedImage:[UIImage imageNamed:@"pe_pen_scale_push"]];
        [sView setUserInteractionEnabled:YES];
        UIPanGestureRecognizer *panGes = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(scaleTextView:)];
        [sView addGestureRecognizer:panGes]; [panGes release];
        
        [sView setExclusiveTouch:YES]; [self addSubview:sView];
        [self setScaleView:sView]; [sView release];
        
        [self layoutSubViewWithFrame:frame]; self.isEditting = YES;

        // temp init setting, replace later
        CGFloat cFont = 1; self.textView.text = text; self.minSize = minSize;
        
        if (minSize.height >  frame.size.height ||
            minSize.width  >  frame.size.width  ||
            minSize.height <= 0 || minSize.width <= 0)
        {
            self.minSize = CGSizeMake(frame.size.width/3.f, frame.size.height/3.f);
        }
        CGSize  tSize = IS_IOS_7?[self textSizeWithFont:cFont text:[text length]?nil:@"A"]:CGSizeZero;

        do
        {
            if (IS_IOS_7)
            {
                tSize = [self textSizeWithFont:++cFont text:[text length]?nil:@"A"];
            }
            else
            {
                [self.textView setFont:[self.curFont fontWithSize:++cFont]];
            }
        }
        while (![self isBeyondSize:tSize] && cFont < MAX_FONT_SIZE);
    
        if (cFont < /*self.minFontSize*/0) return nil;
        
        cFont = (cFont < MAX_FONT_SIZE) ? cFont : self.minFontSize;
        [self.textView setFont:[self.curFont fontWithSize:--cFont]];
        
        self.textCenter = CGPointMake(frame.origin.x+frame.size.width/2.f,
                                      frame.origin.y+frame.size.height/2.f);
        
        #if TEST_CENTER_ALIGNMENT
        self.indicatorView = [[[UIImageView alloc] initWithFrame:CGRectZero] autorelease];
        [self.indicatorView setBackgroundColor:[[UIColor redColor] colorWithAlphaComponent:0.5]];
        [self addSubview:self.indicatorView];
        #else
        // ...
        #endif
        
        [self centerTextVertically];
    }
    return self;
}

- (void)createTextViewWithFrame:(CGRect)frame text:(NSString *)text font:(UIFont *)font
{
    CTextView *textView = [[CTextView alloc] initWithFrame:frame];
    
    textView.scrollEnabled = NO; [textView setDelegate:self];
    textView.keyboardType  = UIKeyboardTypeASCIICapable;
    textView.returnKeyType = UIReturnKeyDone;
    textView.textAlignment = NSTextAlignmentCenter;

    [textView setBackgroundColor:[UIColor clearColor]];
    [textView setTextColor:self.tColor];
    [textView setText:text]; [textView setFont:font];
    [textView setAutocorrectionType:UITextAutocorrectionTypeNo];
    [self addSubview:textView]; [self sendSubviewToBack:textView];
    
    if (IS_IOS_7)
    {
        textView.textContainerInset = UIEdgeInsetsZero;
    }
    else
    {
        textView.contentOffset = CGPointZero;
    }
    
    [self setTextView:textView]; [textView release];
}

- (void)layoutSubViewWithFrame:(CGRect)frame
{
    CGRect tRect = frame;
    
    tRect.size.width  = self.frame.size.width -PEN_ICON_SIZE-EDIT_BOX_LINE;
    tRect.size.height = self.frame.size.height-PEN_ICON_SIZE-EDIT_BOX_LINE;
    
    tRect.origin.x = (self.frame.size.width -tRect.size.width) /2.;
    tRect.origin.y = (self.frame.size.height-tRect.size.height)/2.;
    
    [self.textView setFrame:tRect];

    [self.editButton setFrame:CGRectMake(0, self.frame.size.height-PEN_ICON_SIZE,
                                         PEN_ICON_SIZE, PEN_ICON_SIZE)];
    [self.scaleView  setFrame:CGRectMake(self.frame.size.width-PEN_ICON_SIZE,
                                         0, PEN_ICON_SIZE, PEN_ICON_SIZE)];
}

- (void)editTextView
{
    NSString *text = self.textView.text;  UIFont *font = self.textView.font;
    CGRect   frame = self.textView.frame; [self.textView removeFromSuperview];
    
    self.isEditting = YES; [self showTextViewBox];
    
    [self createTextViewWithFrame:frame text:text font:font];
    [self centerTextVertically]; [self.textView becomeFirstResponder];
}

- (void)hideTextViewBox
{
    [self.editButton setHidden:YES];
    [self.scaleView  setHidden:YES];

    [self endEditing:YES]; self.isEditting = NO;    
    self.hideView = YES; [self setNeedsDisplay];
}

- (void)showTextViewBox
{
    [self.editButton setHidden:NO];
    [self.scaleView  setHidden:NO];
    
    self.hideView = NO;  [self setNeedsDisplay];
}

- (void)scaleTextView:(UIPanGestureRecognizer *)panGes
{
    if (panGes.state == UIGestureRecognizerStateBegan)
    {
        [self endEditing:YES]; self.isEditting = NO;
        self.textCenter = self.center; [self.scaleView setHighlighted:YES];
    }
    
    if (panGes.state == UIGestureRecognizerStateChanged)
    {
        CGPoint translation = [panGes translationInView:self];
        CGFloat x = translation.x; CGFloat y = -translation.y;

        if ( (x >  2.f && y >  2.f ) || (x < -2.f && y < -2.f) )
        {
            CGFloat wScale = x / self.frame.size.width +1;
            CGFloat hScale = y / self.frame.size.height+1;
            
            CGFloat scale    = MIN(wScale, hScale);
            CGRect  tempRect = self.frame;
            tempRect.size.width  *= scale;
            tempRect.size.height *= scale;

            if (x > 0.f && y > 0.f) // zoom out
            {
                CGFloat cX = self.superview.frame.size.width -tempRect.size.width;
                CGFloat cY = self.superview.frame.size.height-tempRect.size.height;
                
                if (cX > 0 && cY < 0)
                {
                    CGFloat scale = tempRect.size.width/tempRect.size.height;
                    tempRect.size.height += cY;
                    tempRect.size.width   = tempRect.size.height*scale;
                }
                else if (cX < 0 && cY > 0)
                {
                    CGFloat scale = tempRect.size.height/tempRect.size.width;
                    tempRect.size.width += cX;
                    tempRect.size.height = tempRect.size.width*scale;
                }
                else if (cX < 0 && cY < 0)
                {
                    if (cX < cY)
                    {
                        CGFloat scale = tempRect.size.height/tempRect.size.width;
                        tempRect.size.width += cX;
                        tempRect.size.height = tempRect.size.width*scale;
                    }
                    else
                    {
                        CGFloat scale = tempRect.size.width/tempRect.size.height;
                        tempRect.size.height += cY;
                        tempRect.size.width   = tempRect.size.height*scale;
                    }
                }
            }
            
            BOOL beyondMin = tempRect.size.width <self.minSize.width ||
                             tempRect.size.height<self.minSize.height;
            
            if (x < 0 && beyondMin) tempRect.size = self.minSize;
            
            tempRect.origin.x = self.textCenter.x- tempRect.size.width/2;
            tempRect.origin.y = self.textCenter.y-tempRect.size.height/2;

            if (tempRect.origin.x < 0)
            {
                CGPoint pC = self.textCenter;
                
                pC.x = tempRect.size.width/2.f;  self.textCenter = pC;
            }
            
            if (tempRect.origin.y < 0)
            {
                CGPoint pC = self.textCenter;
                
                pC.y = tempRect.size.height/2.f; self.textCenter = pC;
            }
            
            if (tempRect.origin.x+tempRect.size.width > self.superview.frame.size.width)
            {
                CGPoint pC = self.textCenter;
                pC.x -= (tempRect.origin.x+tempRect.size.width-self.superview.frame.size.width);
                self.textCenter = pC;
            }
            
            if (tempRect.origin.y+tempRect.size.height > self.superview.frame.size.height)
            {
                CGPoint pC = self.textCenter;
                pC.y -= (tempRect.origin.y+tempRect.size.height-self.superview.frame.size.height);
                self.textCenter = pC;
            }

            [self setFrame:tempRect]; [self setCenter:self.textCenter];

            [self layoutSubViewWithFrame:tempRect];
            
            if (IS_IOS_7)
            {
                self.textView.textContainerInset = UIEdgeInsetsZero;
            }
            else
            {
                self.textView.contentOffset = CGPointZero;
            }
            
            if ([self.textView.text length])
            {
                CGFloat cFont = self.textView.font.pointSize;
                CGSize  tSize = IS_IOS_7?[self textSizeWithFont:cFont text:nil]:CGSizeZero;
                
                if (x > 0.f && y > 0.f)
                {
                    do
                    {
                        if (IS_IOS_7)
                        {
                            tSize = [self textSizeWithFont:++cFont text:nil];
                        }
                        else
                        {
                            [self.textView setFont:[self.curFont fontWithSize:++cFont]];
                        }
                    }
                    while (![self isBeyondSize:tSize] && cFont < MAX_FONT_SIZE);
                    
                    cFont = (cFont < MAX_FONT_SIZE) ? cFont : self.minFontSize;
                    [self.textView setFont:[self.curFont fontWithSize:--cFont]];
                }
                else
                {
                    while ([self isBeyondSize:tSize] && cFont > 0)
                    {
                        if (IS_IOS_7)
                        {
                            tSize = [self textSizeWithFont:--cFont text:nil];
                        }
                        else
                        {
                            [self.textView setFont:[self.curFont fontWithSize:--cFont]];
                        }
                    }
                    
                    [self.textView setFont:[self.curFont fontWithSize:cFont]];
                }
            }
            
            if (!IS_IOS_7) // solve strange bugs for iOS 6
            {
                NSString *text = self.textView.text; UIFont *font = self.textView.font;
                CGRect frame = self.textView.frame; [self.textView removeFromSuperview];
                
                [self createTextViewWithFrame:frame text:text font:font];
            }
            
            [self centerTextVertically]; [self setNeedsDisplay];
            [panGes setTranslation:CGPointZero inView:self];
        }
    }

    if (panGes.state == UIGestureRecognizerStateEnded     ||
        panGes.state == UIGestureRecognizerStateCancelled ||
        panGes.state == UIGestureRecognizerStateFailed    )
    {
        [self.scaleView setHighlighted:NO]; [self centerTextVertically];
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@"\n"])
    {
        [self endEditing:YES];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(textViewDidEndEditing:)])
        {
            [self.delegate textViewDidEndEditing:self];
        }
        return NO;
    }
    
    _isDeleting = (range.length >= 1 && text.length == 0);
    
    if (textView.font.pointSize <= self.minFontSize && !_isDeleting) return NO;
    
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
    NSString *calcStr = textView.text;
    
    if (![textView.text length]) [self.textView setText:@"A"];
    
    CGFloat cFont = self.textView.font.pointSize;
    CGSize  tSize = IS_IOS_7?[self textSizeWithFont:cFont text:nil]:CGSizeZero;
    
    if (IS_IOS_7)
    {
        self.textView.textContainerInset = UIEdgeInsetsZero;
    }
    else
    {
        self.textView.contentOffset = CGPointZero;
    }
    
    if (_isDeleting)
    {
        do
        {
            if (IS_IOS_7)
            {
                tSize = [self textSizeWithFont:++cFont text:nil];
            }
            else
            {
                [self.textView setFont:[self.curFont fontWithSize:++cFont]];
            }
        }
        while (![self isBeyondSize:tSize] && cFont < MAX_FONT_SIZE);
        
        cFont = (cFont < MAX_FONT_SIZE) ? cFont : self.minFontSize;
        [self.textView setFont:[self.curFont fontWithSize:--cFont]];
    }
    else
    {
        while ([self isBeyondSize:tSize] && cFont > 0)
        {
            if (IS_IOS_7)
            {
                tSize = [self textSizeWithFont:--cFont text:nil];
            }
            else
            {
                [self.textView setFont:[self.curFont fontWithSize:--cFont]];
            }
        }
        
        [self.textView setFont:[self.curFont fontWithSize:cFont]];
    }
    
    [self centerTextVertically]; [self.textView setText:calcStr];
}

- (CGSize)textSizeWithFont:(CGFloat)font text:(NSString *)string
{
    NSString *text = string ? string : self.textView.text;
    
    CGFloat pO = self.textView.textContainer.lineFragmentPadding * 2;
    CGFloat cW = self.textView.frame.size.width - pO;
    
    CGSize  tH = [text sizeWithFont:[self.curFont fontWithSize:font]
                  constrainedToSize:CGSizeMake(cW, MAXFLOAT)
                      lineBreakMode:NSLineBreakByWordWrapping];
    return  tH;
}

- (BOOL)isBeyondSize:(CGSize)size
{
    if (IS_IOS_7)
    {
        CGFloat ost = _textView.textContainerInset.top + _textView.textContainerInset.bottom;
        
        return size.height + ost > self.textView.frame.size.height;
    }
    else
    {
        return self.textView.contentSize.height > self.textView.frame.size.height;
    }
}

- (void)centerTextVertically
{
    if (IS_IOS_7)
    {
        CGSize  tH     = [self textSizeWithFont:self.textView.font.pointSize text:nil];
        CGFloat offset = (self.textView.frame.size.height - tH.height)/2.f;
        
        self.textView.textContainerInset = UIEdgeInsetsMake(offset, 0, offset, 0);
    }
    else
    {
        CGFloat fH = self.textView.frame.size.height;
        CGFloat cH = self.textView.contentSize.height;
        
        [self.textView setContentOffset:CGPointMake(0, (cH-fH)/2.f)];
    }
    
    #if TEST_CENTER_ALIGNMENT
    [self.indicatorView setFrame:CGRectMake(0, offset, self.frame.size.width, tH.height)];
    #else
    // ...
    #endif
}

- (void)drawRect:(CGRect)rect
{
    // Drawing code
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetRGBStrokeColor(context, 1, 1, 1, !_hideView);
    CGContextSetLineWidth(context, EDIT_BOX_LINE);
    
    CGRect drawRect       = self.textView.frame;
    drawRect.size.width  += EDIT_BOX_LINE;
    drawRect.size.height += EDIT_BOX_LINE;
    drawRect.origin.x     = (self.frame.size.width-drawRect.size.width)/2.f;
    drawRect.origin.y     = (self.frame.size.height-drawRect.size.height)/2.f;

    CGContextAddRect(context, drawRect);
    
    CGContextStrokePath(context);
}

- (void)dealloc
{
    self.textView = nil;
    self.editButton = nil;
    self.scaleView = nil;
    self.tColor = nil;
    self.curFont = nil;
    self.indicatorView = nil;
    [super dealloc];
}

@end
