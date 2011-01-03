/*********************************************************************************
 
 © Copyright 2010-2011, Isaac Greenspan
 
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 
 *********************************************************************************/

//
//  IGResizableComboBox.m
//

#import "IGResizableComboBox.h"

#define RESIZE_HANDLE_HEIGHT 7.0

#define RESIZE_HANDLE_IMAGE_HEIGHT 1.0
#define RESIZE_HANDLE_IMAGE_WIDTH 30.0

#pragma mark -
#pragma mark Private helper class's interface

// this interface-only section avoids the "may not respond to selector" warning
// in IGResizableComboBoxPopUpContentView's forwardingTargetForSelector:
@interface NSView (forwardingTargetForSelector)
- (id) forwardingTargetForSelector:(SEL)selector;
@end


@interface IGResizableComboBoxPopUpContentView : NSView {
	IGResizableComboBox *theComboBox;
	NSScrollView *theScrollView;
	
	CGFloat draggingBasisY;
	BOOL draggingNow;
}

@property(retain) IGResizableComboBox *theComboBox;
@property(retain) NSScrollView *theScrollView;

//<#methods#>

@end

@interface IGResizableComboBoxPopUpHandleImageView : NSImageView {
}

//<#methods#>

@end


#pragma mark -
#pragma mark main class implementation

@implementation IGResizableComboBox

@synthesize isPopUpOpen;

- (id)initWithFrame:(NSRect)frame {
//	NSLog(@"initWithFrame:");
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		[self awakeFromNib];
		[self setNumberOfVisibleItemsAutosaveName:nil];
		isHandleDrawn = NO;
    }
    return self;
}

- (void)awakeFromNib
{
//	NSLog(@"awakeFromNib");
	[self setIsPopUpOpen:NO];
//	NSLog(@"setting notifications...");
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(willPopUp:)
												 name:NSComboBoxWillPopUpNotification
											   object:self];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(willDismiss:)
												 name:NSComboBoxWillDismissNotification
											   object:self];
//	NSLog(@"done.");
}

- (NSWindow *)comboBoxPopUpWindow
{
	NSWindow *child = nil;
	if ([self isPopUpOpen]) {
		for (child in [[self window] childWindows]) {
			if ([[child className] isEqualToString:@"NSComboBoxWindow"]) {
				break;
			}
		}
	}
	return child;
}

- (BOOL)isPopUpBelow
{
	if ([self isPopUpOpen]) {
		NSRect popUpFrame = [[self comboBoxPopUpWindow] frame];
		CGFloat popUpTopInScreenY = popUpFrame.origin.y + popUpFrame.size.height;
		NSPoint selfOriginInSelf = [self bounds].origin;
		NSPoint selfOriginInWindow = [self convertPoint:selfOriginInSelf
												 toView:nil];
		CGFloat selfOriginInScreenY = [[self window] convertBaseToScreen:selfOriginInWindow].y;
		return (popUpTopInScreenY < selfOriginInScreenY);
	} else {
		return NO;
	}
}

- (BOOL)isPopUpAbove
{
	return [self isPopUpOpen] && ![self isPopUpBelow];
}

- (void)drawHandle {
	//		NSUInteger numberOfDisplayedLines = MIN([self numberOfVisibleItems],MAX(1,[self numberOfItems]));
	NSWindow *child = [self comboBoxPopUpWindow];
	if (child) {
		NSRect windowFrame = [child frame];
		NSScrollView *scrollView = [child contentView];
		NSRect scrollViewFrame = [scrollView frame];
		NSRect handleImageViewFrame;
		
		windowFrame.size.height += RESIZE_HANDLE_HEIGHT;
		
		if ([self isPopUpAbove]) {
			// the pop-up is above
			handleImageViewFrame = NSMakeRect(0.0, windowFrame.size.height - RESIZE_HANDLE_HEIGHT, // TODO: fix
											  windowFrame.size.width, RESIZE_HANDLE_HEIGHT);
		} else {
			// the pop-up is not above
			windowFrame.origin.y -= RESIZE_HANDLE_HEIGHT;
			scrollViewFrame.origin.y += RESIZE_HANDLE_HEIGHT;
			handleImageViewFrame = NSMakeRect(0.0, 0.0,
											  windowFrame.size.width, RESIZE_HANDLE_HEIGHT);
		}
		
		[child setFrame:windowFrame display:YES];
		
		innerView = [[IGResizableComboBoxPopUpContentView alloc] initWithFrame:scrollViewFrame];
		[innerView setTheComboBox:self];
		[innerView setTheScrollView:scrollView];
		[child setContentView:innerView];
		[innerView addSubview:scrollView];
		[scrollView setFrame:scrollViewFrame];
		
		IGResizableComboBoxPopUpHandleImageView *handleImageView;
		handleImageView = [[[IGResizableComboBoxPopUpHandleImageView alloc]
							initWithFrame:handleImageViewFrame]
						   autorelease];
		NSImage *image = [[[NSImage alloc]
						   initWithSize:NSMakeSize(windowFrame.size.width, RESIZE_HANDLE_HEIGHT)]
						  autorelease];
		[image lockFocus];
		[[NSColor controlShadowColor] set];
		[NSBezierPath fillRect:NSMakeRect((windowFrame.size.width - RESIZE_HANDLE_IMAGE_WIDTH)/2,
										  (RESIZE_HANDLE_HEIGHT - RESIZE_HANDLE_IMAGE_HEIGHT)/2,
										  RESIZE_HANDLE_IMAGE_WIDTH,
										  RESIZE_HANDLE_IMAGE_HEIGHT)];
		[[NSColor headerColor] set];
		[NSBezierPath strokeLineFromPoint:NSMakePoint(0.0, 0.0)
								  toPoint:NSMakePoint(windowFrame.size.width, 0.0)];
		[NSBezierPath strokeLineFromPoint:NSMakePoint(0.0, RESIZE_HANDLE_HEIGHT)
								  toPoint:NSMakePoint(windowFrame.size.width, RESIZE_HANDLE_HEIGHT)];
		[image unlockFocus];
		[handleImageView setImage:image];
		[innerView addSubview:handleImageView];
	}
	isHandleDrawn = YES;
}

- (void)drawRect:(NSRect)dirtyRect {
    // Drawing code here.
	[super drawRect:dirtyRect];
	if ([self isPopUpOpen] && !isHandleDrawn) {
		[self drawHandle];
	} else {
	}
}

- (void)setNumberOfVisibleItems:(NSInteger)visibleItems
{
	[super setNumberOfVisibleItems:visibleItems];
	if (numberOfVisibleItemsAutosaveName) {
		[[NSUserDefaults standardUserDefaults] setInteger:visibleItems
												   forKey:numberOfVisibleItemsAutosaveName];
	}
}

- (void)setNumberOfVisibleItemsAutosaveName:(NSString *)name
{
//	NSLog(@"changing combobox length autosave name from '%@' to '%@'",numberOfVisibleItemsAutosaveName,name);
	[numberOfVisibleItemsAutosaveName release];
	numberOfVisibleItemsAutosaveName = [name copy];
	[self setNumberOfVisibleItems:[[NSUserDefaults standardUserDefaults]
								   integerForKey:numberOfVisibleItemsAutosaveName]];
}


- (void)willPopUp:(NSNotification *)notification
{
//	NSLog(@"willPopUp:");
	[self setIsPopUpOpen:YES];
}

- (void)willDismiss:(NSNotification *)notification
{
	NSScrollView *scrollView = [innerView theScrollView];
	[[innerView window] setContentView:scrollView];
//	NSLog(@"willDismiss:");
	[self setIsPopUpOpen:NO];
	isHandleDrawn = NO;
}

@end


#pragma mark -
#pragma mark Private helper class's implementation

@implementation IGResizableComboBoxPopUpContentView

@synthesize theComboBox;
@synthesize theScrollView;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		draggingBasisY = 0.0;
		draggingNow = NO;
		[self setTheComboBox:nil];
		[self setTheScrollView:nil];
    }
    return self;
}

// to allow catching of calls that should go to our inner view
- (id)forwardingTargetForSelector:(SEL)aSelector
{
	if (aSelector == @selector(verticalScroller)) {
		return theScrollView;
	}
	if ([super respondsToSelector:@selector(forwardingTargetForSelector:)]) {
		return [super forwardingTargetForSelector:aSelector];
	} else {
		[self doesNotRecognizeSelector:aSelector];
		return nil;
	}

}


- (void)mouseDown:(NSEvent *)theEvent
{
	draggingBasisY = [NSEvent mouseLocation].y;
	draggingNow = YES;
	[[NSCursor resizeUpDownCursor] push];
}

- (void)mouseUp:(NSEvent *)theEvent
{
	draggingBasisY = 0.0;
	draggingNow = NO;
	[NSCursor pop];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	CGFloat newY = [NSEvent mouseLocation].y;
	CGFloat realItemHeight = [theComboBox itemHeight] + [theComboBox intercellSpacing].height;
	if (fabs(draggingBasisY - newY) > realItemHeight/2) {
		// if we're more than half-way to a change of one item height, then we actually resize
		BOOL isAbove = [theComboBox isPopUpAbove];
		
		CGFloat delta_y;
		if (isAbove) {
			// the pop-up is above; don't let the y position move below a minimum of height 1 line
			delta_y = realItemHeight * MIN([theComboBox numberOfVisibleItems] - 1,
												   round((draggingBasisY - newY) / realItemHeight));
		} else {
			// the pop-up is not above; don't let the y position move above a minimum of height 1 line
			delta_y = realItemHeight * MAX(1 - [theComboBox numberOfVisibleItems],
												   round((draggingBasisY - newY) / realItemHeight));
		}
		draggingBasisY -= delta_y;
		
		NSWindow *popup = [self window];
		NSRect windowFrame = [popup frame];
		CGFloat previousHeight = windowFrame.size.height;
		
		if (isAbove) {
			// the pop-up is above
			windowFrame.size.height = MAX(windowFrame.size.height - delta_y,RESIZE_HANDLE_HEIGHT + realItemHeight);
			IGResizableComboBoxPopUpHandleImageView *handleImageView = nil;
			for (NSView *aView in [self subviews]) {
				if ([aView isKindOfClass:[IGResizableComboBoxPopUpHandleImageView class]]) {
					handleImageView = (IGResizableComboBoxPopUpHandleImageView *)aView;
				}
			}
			if (handleImageView) {
				NSRect handleImageViewFrame = [handleImageView frame];
				handleImageViewFrame.origin.y += windowFrame.size.height - previousHeight;
				[handleImageView setFrame:handleImageViewFrame];
			}
		} else {
			// the pop-up is not above
			windowFrame.size.height = MAX(windowFrame.size.height + delta_y,RESIZE_HANDLE_HEIGHT + realItemHeight);
			windowFrame.origin.y -= windowFrame.size.height - previousHeight;
		}
		
		[popup setFrame:windowFrame display:YES];
		
		NSInteger newNumberOfVisibleItems = round((windowFrame.size.height - RESIZE_HANDLE_HEIGHT)/realItemHeight);
		[theComboBox setNumberOfVisibleItems:newNumberOfVisibleItems];
	}
}

@end

@implementation IGResizableComboBoxPopUpHandleImageView

- (void)mouseDown:(NSEvent *)theEvent
{
	[[self superview] mouseDown:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent
{
	[[self superview] mouseUp:theEvent];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	[[self superview] mouseDragged:theEvent];
}

@end
