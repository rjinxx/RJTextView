//
//  RJTextView.h
//  RJTextViewDemo
//
//  Created by Rylan on 3/11/15.
//  Copyright (c) 2015 ArcSoft. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RJTextView;

@protocol RJTextViewDelegate <NSObject>
@optional

- (void)textViewDidEndEditing:(RJTextView *)textView;

@end

@interface CTextView : UITextView

@end

@interface RJTextView : UIView

/*
 RECOMMEND INITIALIZTION:
 Frame:CGRectMake(85, 100, 150, 155) defaultText:@"LIFE IS\nBUT A\nDREAM"];
*/
- (id)initWithFrame:(CGRect)frame
        defaultText:(NSString *)text
               font:(UIFont *)font
              color:(UIColor *)color
            minSize:(CGSize)minSize;

// property setting
@property (nonatomic, assign) id<RJTextViewDelegate> delegate;

// read only
@property (nonatomic, retain, readonly) CTextView *textView;
@property (nonatomic, assign, readonly) BOOL isEditting;

- (void)showTextViewBox;

@end
