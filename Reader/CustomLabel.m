//
//  CustomLabel.m
//  Reader
//
//  Created by wiz on 13-3-8.
//  Copyright (c) 2013年 wiz. All rights reserved.
//

#import "CustomLabel.h"

@implementation CustomLabel

 - (void)setDefaults
{
    gradientStartPoint = CGPointMake(0.5f, 0.0f);
    gradientEndPoint = CGPointMake(0.5f, 0.75f);
}

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        self.backgroundColor = nil;
        [self setDefaults];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
    {
        [self setDefaults];
    }
    return self;
}

- (void)setShadowBlur:(CGFloat)blur
{
    if (shadowBlur != blur)
    {
        shadowBlur = blur;
        [self setNeedsDisplay];
    }
}

- (void)setInnerShadowOffset:(CGSize)offset
{
    if (!CGSizeEqualToSize(innerShadowOffset, offset))
    {
        innerShadowOffset = offset;
        [self setNeedsDisplay];
    }
}

- (void)setInnerShadowColor:(UIColor *)color
{
    if (innerShadowColor != color)
    {
        [innerShadowColor release];
        innerShadowColor = [color retain];
        [self setNeedsDisplay];
    }
}

- (void)setGradientStartColor:(UIColor *)color
{
    if (gradientStartColor != color)
    {
        [gradientStartColor release];
        gradientStartColor = [color retain];
        [self setNeedsDisplay];
    }
}

- (void)setGradientEndColor:(UIColor *)color
{
    if (gradientEndColor != color)
    {
        [gradientEndColor release];
        gradientEndColor = [color retain];
        [self setNeedsDisplay];
    }
}

- (void)getComponents:(CGFloat *)rgba forColor:(CGColorRef)color
{
    CGColorSpaceModel model = CGColorSpaceGetModel(CGColorGetColorSpace(color));
    const CGFloat *components = CGColorGetComponents(color);
    switch (model)
    {
        case kCGColorSpaceModelMonochrome:
        {
            rgba[0] = components[0];
            rgba[1] = components[0];
            rgba[2] = components[0];
            rgba[3] = components[1];
            break;
        }
        case kCGColorSpaceModelRGB:
        {
            rgba[0] = components[0];
            rgba[1] = components[1];
            rgba[2] = components[2];
            rgba[3] = components[3];
            break;
        }
        default:
        {
            NSLog(@"Unsupported gradient color format: %i", model);
            rgba[0] = 0.0f;
            rgba[1] = 0.0f;
            rgba[2] = 0.0f;
            rgba[3] = 1.0f;
            break;
        }
    }
}

- (CGColorRef)color:(CGColorRef)a blendedWithColor:(CGColorRef)b
{
    CGFloat aRGBA[4];
    [self getComponents:aRGBA forColor:a];
    if (aRGBA[3] == 1.0f)
    {
        return [UIColor colorWithRed:aRGBA[0] green:aRGBA[1] blue:aRGBA[2] alpha:aRGBA[3]].CGColor;
    }
    
    CGFloat bRGBA[4];
    [self getComponents:bRGBA forColor:b];
    CGFloat source = aRGBA[3];
    CGFloat dest = 1.0f - source;
    return [UIColor colorWithRed:source * aRGBA[0] + dest * bRGBA[0]
                           green:source * aRGBA[1] + dest * bRGBA[1]
                            blue:source * aRGBA[2] + dest * bRGBA[2]
                           alpha:bRGBA[3] + (1.0f - bRGBA[3]) * aRGBA[3]].CGColor;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //get label size
    CGRect textRect = rect;
    CGFloat fontSize = self.font.pointSize;
    if (self.adjustsFontSizeToFitWidth)
    {
        textRect.size = [self.text sizeWithFont:self.font
                                    minFontSize:self.minimumFontSize
                                 actualFontSize:&fontSize
                                       forWidth:rect.size.width
                                  lineBreakMode:self.lineBreakMode];
    }
    else
    {
        textRect.size = [self.text sizeWithFont:self.font
                                       forWidth:rect.size.width
                                  lineBreakMode:self.lineBreakMode];
    }
    
    //set font
    UIFont *font = [self.font fontWithSize:fontSize];
    
    //set position
    switch (self.textAlignment)
    {
        case UITextAlignmentCenter:
        {
            textRect.origin.x = (rect.size.width - textRect.size.width) / 2.0f;
            break;
        }
        case UITextAlignmentRight:
        {
            textRect.origin.x = rect.size.width - textRect.size.width;
            break;
        }
    }
    switch (self.contentMode)
    {
        case UIViewContentModeTop:
        case UIViewContentModeTopLeft:
        case UIViewContentModeTopRight:
        {
            textRect.origin.y = 0.0f;
            break;
        }
        case UIViewContentModeBottom:
        case UIViewContentModeBottomLeft:
        case UIViewContentModeBottomRight:
        {
            textRect.origin.y = rect.size.height - textRect.size.height;
            break;
        }
        default:
        {
            textRect.origin.y = (rect.size.height - textRect.size.height)/2.0f;
            break;
        }
    }
    
    BOOL hasShadow = self.shadowColor &&
    ![self.shadowColor isEqual:[UIColor clearColor]] &&
    (shadowBlur > 0.0f || !CGSizeEqualToSize(self.shadowOffset, CGSizeZero));
    
    BOOL hasInnerShadow = innerShadowColor &&
    ![self.innerShadowColor isEqual:[UIColor clearColor]] &&
    !CGSizeEqualToSize(innerShadowOffset, CGSizeZero);
    
    BOOL hasGradient = gradientStartColor && gradientEndColor;
    
    BOOL needsMask = hasInnerShadow || hasGradient;
    
    CGImageRef alphaMask = NULL;
    if (needsMask)
    {
        //draw mask
        CGContextSaveGState(context);
        [self.text drawInRect:textRect withFont:font lineBreakMode:self.lineBreakMode alignment:self.textAlignment];
        CGContextRestoreGState(context);
        
        // Create an image mask from what we've drawn so far
        alphaMask = CGBitmapContextCreateImage(context);
        
        //clear the context
        CGContextClearRect(context, textRect);
    }
    
    //set up shadow
    if (hasShadow)
    {
        CGContextSaveGState(context);
        CGFloat textAlpha = CGColorGetAlpha(self.textColor.CGColor);
        CGContextSetShadowWithColor(context, self.shadowOffset, shadowBlur, self.shadowColor.CGColor);
        [needsMask? [self.shadowColor colorWithAlphaComponent:textAlpha]: self.textColor setFill];
        [self.text drawInRect:textRect withFont:font lineBreakMode:self.lineBreakMode alignment:self.textAlignment];
        CGContextRestoreGState(context);
    }
    
    if (needsMask)
    {
        //clip the context
        CGContextSaveGState(context);
        CGContextTranslateCTM(context, 0, rect.size.height);
        CGContextScaleCTM(context, 1.0, -1.0);
        CGContextClipToMask(context, rect, alphaMask);
        
        if (hasInnerShadow)
        {
            //fill inner shadow
            [innerShadowColor setFill];
            CGContextFillRect(context, textRect);
            
            //clip to unshadowed part
            CGContextTranslateCTM(context, innerShadowOffset.width, -innerShadowOffset.height);
            CGContextClipToMask(context, rect, alphaMask);
        }
        
        if (hasGradient)
        {
            //pre-blend
            CGColorRef startColor = [self color:gradientStartColor.CGColor blendedWithColor:self.textColor.CGColor];
            CGColorRef endColor = [self color:gradientEndColor.CGColor blendedWithColor:self.textColor.CGColor];
            
            //draw gradient
            CGContextScaleCTM(context, 1.0, -1.0);
            CGContextTranslateCTM(context, 0, -rect.size.height);
            CFArrayRef colors = (CFArrayRef)[NSArray arrayWithObjects:(id)startColor, (id)endColor, nil];
            CGGradientRef gradient = CGGradientCreateWithColors(NULL, colors, NULL);
            CGPoint startPoint = CGPointMake(textRect.origin.x + gradientStartPoint.x * textRect.size.width,
                                             textRect.origin.y + gradientStartPoint.y * textRect.size.height);
            CGPoint endPoint = CGPointMake(textRect.origin.x + gradientEndPoint.x * textRect.size.width,
                                           textRect.origin.y + gradientEndPoint.y * textRect.size.height);
            CGContextDrawLinearGradient(context, gradient, startPoint, endPoint,
                                        kCGGradientDrawsAfterEndLocation | kCGGradientDrawsBeforeStartLocation);
            CGGradientRelease(gradient);
        }
        else
        {
            //fill text
            [self.textColor setFill];
            CGContextFillRect(context, textRect);
        }
        
        //end clipping
        CGContextRestoreGState(context);
        CGImageRelease(alphaMask);
    }
}

- (void)dealloc
{
    [innerShadowColor release];
    [gradientStartColor release];
    [gradientEndColor release];
    [super dealloc];
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
