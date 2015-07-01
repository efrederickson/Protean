//
//  UIDiscreteSlider.m
//  UIDiscreteSlider
//
//  Created by Phillip Harris on 4/23/14.
//  Copyright (c) 2014 Phillip Harris. All rights reserved.
//

#import "UIDiscreteSlider.h"

@implementation UIDiscreteSlider

//===============================================
#pragma mark -
#pragma mark Initialization
//===============================================

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    
    _increment = 0.25;
    
    self.minimumTrackTintColor = [UIColor colorWithWhite:0.7 alpha:1.0];
    self.maximumTrackTintColor = [UIColor colorWithWhite:0.7 alpha:1.0];
}

//===============================================
#pragma mark -
#pragma mark Draw Rect
//===============================================

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithWhite:0.7 alpha:1.0].CGColor);
    CGContextSetLineWidth(context, 1.0);
    
    CGRect trackRect = [self trackRectForBounds:self.bounds];
    
    CGRect minimumThumbRect = [self thumbRectForBounds:self.bounds trackRect:trackRect value:self.minimumValue];
    CGRect maximumThumbRect = [self thumbRectForBounds:self.bounds trackRect:trackRect value:self.maximumValue];
    
    float totalValueDelta = (self.maximumValue - self.minimumValue);
    
    int totalNumberOfSteps = (int)(totalValueDelta / self.increment);
    
    CGFloat leftEdge = CGRectGetMidX(minimumThumbRect);
    CGFloat rightEdge = CGRectGetMidX(maximumThumbRect);
    CGFloat interspace = (rightEdge - leftEdge) / totalNumberOfSteps;
    
    CGFloat desiredLineHeight = 16.0;
    CGFloat yPoint = (CGRectGetHeight(self.frame) - desiredLineHeight) / 2.0;
    
    for (int i = 0; i <= totalNumberOfSteps; i++) {
        
        CGFloat xPoint = roundf(leftEdge + interspace * i);
        
        CGContextMoveToPoint(context, xPoint, yPoint);
        CGContextAddLineToPoint(context, xPoint, yPoint + desiredLineHeight);
        CGContextStrokePath(context);
    }
}

//===============================================
#pragma mark -
#pragma mark UIControl Touch Tracking
//===============================================

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    
    BOOL shouldBeginTracking = [super beginTrackingWithTouch:touch withEvent:event];
    
    if (shouldBeginTracking) {
        [self processTouch:touch];
    }
    
    return shouldBeginTracking;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    
    BOOL shouldContinueTracking = [super continueTrackingWithTouch:touch withEvent:event];
    
    if (shouldContinueTracking) {
        [self processTouch:touch];
    }
    
    return YES;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    
    [super endTrackingWithTouch:touch withEvent:event];
    
    [self processTouch:touch];
}

- (void)cancelTrackingWithEvent:(UIEvent *)event {
    
    [super cancelTrackingWithEvent:event];
}

//===============================================
#pragma mark -
#pragma mark Override the Value
//===============================================

- (void)processTouch:(UITouch *)touch {
    
    float fullDelta = (self.maximumValue - self.minimumValue);
    
    float percentage = (self.value - self.minimumValue) / fullDelta;
    
    int totalNumberOfSteps = (int)(fullDelta / self.increment);
    
    float steps = percentage * totalNumberOfSteps;
    
    float newValue = self.minimumValue + self.increment * roundf(steps);
    
    [self setValue:newValue animated:NO];
}
@end