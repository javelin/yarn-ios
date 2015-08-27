//
//  StoryView.m
//  Yarn
//
//  Created by Mark Jundo Documento on 8/14/15.
//  Copyright (c) 2015 Mark Jundo Documento. All rights reserved.
//

#import "StoryView.h"
#import "StoryViewController.h"

@implementation StoryView

static CGFloat arrowAngle = M_PI / 6;
static CGFloat arrowLength = 10.0;

- (id)initWithController:(StoryViewController*)controller {
    self = [super initWithFrame:CGRectMake(1, 1, 1, 1)];
    if (self) {
        _controller = controller;
        [self setBackgroundColor:[UIColor lightGrayColor]];
    }
    
    return self;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [UIColor blueColor].CGColor);
    CGContextSetLineWidth(context, 2.0f);
    
    for (PassageView *pv1 in [[_controller passageViews] allValues]) {
        for (NSNumber *nId in [pv1 linkedIds]) {
            PassageView *pv2 = [_controller getPassageViewWithId:[nId integerValue]];
            if (pv2) {
                CGFloat xDist = [pv2 topSide].x - [pv1 topSide].x;
                CGFloat yDist = [pv2 topSide].y - [pv1 topSide].y;
                CGFloat slope = fabs(xDist / yDist);
                CGPoint p1, p2;
                
                if (slope < 0.8 || slope > 1.3) {
                    // connect sides
                    if (fabs(xDist) > fabs(yDist)) {
                        if (xDist > 0.0) {
                            p1 = [pv1 rightSide];
                            p2 = [pv2 leftSide];
                        }
                        else {
                            p1 = [pv1 leftSide];
                            p2 = [pv2 rightSide];
                        }
                    }
                    else {
                        if (yDist > 0.0) {
                            p1 = [pv1 bottomSide];
                            p2 = [pv2 topSide];
                        }
                        else {
                            p1 = [pv1 topSide];
                            p2 = [pv2 bottomSide];
                        }
                    }
                }
                else {
                    // connect corners
                    if (xDist < 0.0) {
                        if (yDist < 0.0) {
                            p1 = [pv1 topLeftCorner];
                            p2 = [pv2 bottomRightCorner];
                        }
                        else {
                            p1 = [pv1 bottomLeftCorner];
                            p2 = [pv2 topRightCorner];
                        }
                    }
                    else {
                        if (yDist < 0.0) {
                            p1 = [pv1 topRightCorner];
                            p2 = [pv2 bottomLeftCorner];
                        }
                        else {
                            p1 = [pv1 bottomRightCorner];
                            p2 = [pv2 topLeftCorner];
                        }
                    }
                }
                
                CGContextMoveToPoint(context, p1.x, p1.y);
                CGContextAddLineToPoint(context, p2.x, p2.y);
                CGContextStrokePath(context);
                
                CGPoint head1 = [self endPointProjectedFrom:p1 to:p2 angle:arrowAngle distance:arrowLength];
                CGPoint head2 = [self endPointProjectedFrom:p1 to:p2 angle:-arrowAngle distance:arrowLength];
                
                CGContextMoveToPoint(context, head1.x, head1.y);
                CGContextAddLineToPoint(context, p2.x, p2.y);
                CGContextStrokePath(context);
                
                CGContextMoveToPoint(context, p2.x, p2.y);
                CGContextAddLineToPoint(context, head2.x, head2.y);
                CGContextStrokePath(context);
            }
        }
    }
}

- (CGPoint)endPointProjectedFrom:(CGPoint)start to:(CGPoint)end angle:(CGFloat)angle distance:(CGFloat)distance {
    CGFloat length = sqrt(pow(end.x - start.x, 2) + pow(end.y - start.y, 2));
    
    if (length == 0.0)
        return end;
    
    CGFloat lengthRatio = distance / length;
    CGFloat x = end.x - ((end.x - start.x) * cos(angle) -
                         (end.y - start.y) * sin(angle)) * lengthRatio;
    CGFloat y = end.y - ((end.y - start.y) * cos(angle) +
                         (end.x - start.x) * sin(angle)) * lengthRatio;
    
    return CGPointMake(x, y);
}

@end
