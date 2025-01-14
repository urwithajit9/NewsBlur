//
//  FeedTableCell.m
//  NewsBlur
//
//  Created by Samuel Clay on 7/18/11.
//  Copyright 2011 NewsBlur. All rights reserved.
//

#import "NewsBlurAppDelegate.h"
#import "FeedTableCell.h"
#import "UnreadCountView.h"
#import "ABTableViewCell.h"

static UIFont *textFont = nil;

@implementation FeedTableCell

@synthesize appDelegate;
@synthesize feedTitle;
@synthesize feedFavicon;
@synthesize positiveCount = _positiveCount;
@synthesize neutralCount = _neutralCount;
@synthesize negativeCount = _negativeCount;
@synthesize negativeCountStr;
@synthesize isSocial;
@synthesize isSaved;
@synthesize unreadCount;

+ (void) initialize{
    if (self == [FeedTableCell class]) {
        textFont = [UIFont boldSystemFontOfSize:18];
    }
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        appDelegate = [NewsBlurAppDelegate sharedAppDelegate];
        
        unreadCount = [UnreadCountView alloc];
        unreadCount.appDelegate = self.appDelegate;
        self.unreadCount = unreadCount;

        cellContent = [[FeedTableCellView alloc] initWithFrame:self.frame];
        cellContent.opaque = YES;
        
        [self.contentView addSubview:cellContent];
    }

    return self;
}

- (void)drawRect:(CGRect)rect {
    ((FeedTableCellView *)cellContent).cell = self;
    cellContent.frame = rect;
    [cellContent setNeedsDisplay];
    [self setupGestures];
}

- (void) setPositiveCount:(int)ps {
    if (ps == _positiveCount) return;
    
    _positiveCount = ps;
//    [cellContent setNeedsDisplay];
}

- (void) setNeutralCount:(int)nt {
    if (nt == _neutralCount) return;
    
    _neutralCount = nt;
//    [cellContent setNeedsDisplay];
}

- (void) setNegativeCount:(int)ng {
    if (ng == _negativeCount) return;
    
    _negativeCount = ng;
    _negativeCountStr = [NSString stringWithFormat:@"%d", ng];
//    [cellContent setNeedsDisplay];
}

- (void)setupGestures {
    if (self.isSaved) {
        self.shouldDrag = NO;
        return;
    }
    
    [self setDelegate:(NewsBlurViewController <MCSwipeTableViewCellDelegate> *)appDelegate.feedsViewController];
    [self setFirstStateIconName:self.isSocial ? @"menu_icn_fetch_subscribers.png" : @"train.png"
                     firstColor:UIColorFromRGB(0xA4D97B)
            secondStateIconName:nil
                    secondColor:nil
                  thirdIconName:@"g_icn_unread.png"
                     thirdColor:UIColorFromRGB(0xFFFFD2)
                 fourthIconName:nil
                    fourthColor:nil];
    
    self.mode = MCSwipeTableViewCellModeSwitch;
    self.shouldAnimatesIcons = NO;
}

- (void)redrawUnreadCounts {
    [((FeedTableCellView *)cellContent) redrawUnreadCounts];
}

@end

@implementation FeedTableCellView

@synthesize cell;

- (void)drawRect:(CGRect)r {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    UIColor *backgroundColor;
    
    backgroundColor = cell.highlighted || cell.selected ?
                      UIColorFromRGB(0xFFFFD2) :
                      cell.isSocial ? UIColorFromRGB(0xE6ECE8) :
                      cell.isSaved ? UIColorFromRGB(0xE9EBEE) :
                      UIColorFromRGB(0xF7F8F5);

    [backgroundColor set];
    CGContextFillRect(context, r);
    
    if (cell.highlighted || cell.selected) {
//        [NewsBlurAppDelegate fillGradient:CGRectMake(r.origin.x, r.origin.y + 1, r.size.width, r.size.height - 1) startColor:UIColorFromRGB(0xFFFFD2) endColor:UIColorFromRGB(0xFDED8D)];
        
        // top border
        UIColor *highlightBorderColor = UIColorFromRGB(0xE3D0AE);
        CGFloat lineWidth = 0.5f;
        CGContextSetStrokeColor(context, CGColorGetComponents([highlightBorderColor CGColor]));
        CGContextSetLineWidth(context, lineWidth);
        CGContextBeginPath(context);
        CGContextMoveToPoint(context, 0, lineWidth*0.5f);
        CGContextAddLineToPoint(context, r.size.width, 0.5f);
        CGContextStrokePath(context);
        
        // bottom border    
        CGContextBeginPath(context);
        CGContextSetLineWidth(context, lineWidth);
        CGContextMoveToPoint(context, 0, r.size.height - .5f*lineWidth);
        CGContextAddLineToPoint(context, r.size.width, r.size.height - .5f*lineWidth);
        CGContextStrokePath(context);
    }
    
    [cell.unreadCount drawInRect:r ps:cell.positiveCount nt:cell.neutralCount
                        listType:(cell.isSocial ? NBFeedListSocial : cell.isSaved ? NBFeedListSaved : NBFeedListFeed)];

    
    UIColor *textColor = cell.highlighted || cell.selected ?
                         [UIColor blackColor]:
                         UIColorFromRGB(0x3a3a3a);
    UIFont *font;
    NSUserDefaults *userPreferences = [NSUserDefaults standardUserDefaults];
    UIFontDescriptor *fontDescriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleFootnote];
    if (![userPreferences boolForKey:@"use_system_font_size"]) {
        if ([[userPreferences stringForKey:@"feed_list_font_size"] isEqualToString:@"xs"]) {
            fontDescriptor = [fontDescriptor fontDescriptorWithSize:11.0f];
        } else if ([[userPreferences stringForKey:@"feed_list_font_size"] isEqualToString:@"small"]) {
            fontDescriptor = [fontDescriptor fontDescriptorWithSize:12.0f];
        } else if ([[userPreferences stringForKey:@"feed_list_font_size"] isEqualToString:@"medium"]) {
            fontDescriptor = [fontDescriptor fontDescriptorWithSize:13.0f];
        } else if ([[userPreferences stringForKey:@"feed_list_font_size"] isEqualToString:@"large"]) {
            fontDescriptor = [fontDescriptor fontDescriptorWithSize:14.0f];
        } else if ([[userPreferences stringForKey:@"feed_list_font_size"] isEqualToString:@"xl"]) {
            fontDescriptor = [fontDescriptor fontDescriptorWithSize:16.0f];
        }
    }
    if (cell.negativeCount || cell.neutralCount || cell.positiveCount) {
        UIFontDescriptor *boldFontDescriptor = [fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
        font = [UIFont fontWithDescriptor:boldFontDescriptor size:0.0];
    } else {
        font = [UIFont fontWithDescriptor:fontDescriptor size:0.0];
    }
    NSInteger titleOffsetY = ((r.size.height - font.pointSize) / 2) - 2;
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    paragraphStyle.alignment = NSTextAlignmentLeft;
    
    if (cell.isSocial) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            [cell.feedFavicon drawInRect:CGRectMake(9.0, 2.0, 28.0, 28.0)];
            [cell.feedTitle drawInRect:CGRectMake(46, titleOffsetY, r.size.width - ([cell.unreadCount offsetWidth] + 36) - 10 - 16, font.pointSize*1.4)
                   withAttributes:@{NSFontAttributeName: font,
                                    NSForegroundColorAttributeName: textColor,
                                    NSParagraphStyleAttributeName: paragraphStyle}];
        } else {
            [cell.feedFavicon drawInRect:CGRectMake(9.0, 3.0, 26.0, 26.0)];
            [cell.feedTitle drawInRect:CGRectMake(42, titleOffsetY, r.size.width - ([cell.unreadCount offsetWidth] + 36) - 10 - 12, font.pointSize*1.4)
                   withAttributes:@{NSFontAttributeName: font,
                                    NSForegroundColorAttributeName: textColor,
                                    NSParagraphStyleAttributeName: paragraphStyle}];
        }
    } else {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            [cell.feedFavicon drawInRect:CGRectMake(12.0, 7.0, 16.0, 16.0)];
            [cell.feedTitle drawInRect:CGRectMake(36.0, titleOffsetY, r.size.width - ([cell.unreadCount offsetWidth] + 36) - 10, font.pointSize*1.4)
                   withAttributes:@{NSFontAttributeName: font,
                                    NSForegroundColorAttributeName: textColor,
                                    NSParagraphStyleAttributeName: paragraphStyle}];
        } else {
            [cell.feedFavicon drawInRect:CGRectMake(9.0, 7.0, 16.0, 16.0)];
            [cell.feedTitle drawInRect:CGRectMake(34.0, titleOffsetY, r.size.width - ([cell.unreadCount offsetWidth] + 36) - 10, font.pointSize*1.4)
                   withAttributes:@{NSFontAttributeName: font,
                                    NSForegroundColorAttributeName: textColor,
                                    NSParagraphStyleAttributeName: paragraphStyle}];
        }
    }
}

- (void)redrawUnreadCounts {
    if (cell.isSaved) {
        cell.unreadCount.blueCount = cell.positiveCount;
    } else {
        cell.unreadCount.psCount = cell.positiveCount;
        cell.unreadCount.ntCount = cell.neutralCount;
    }
    [cell.unreadCount setNeedsLayout];
}

@end