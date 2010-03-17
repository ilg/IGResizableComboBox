/*********************************************************************************
 
 Copyright (c) 2010, Isaac Greenspan
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 * Neither the name of the <organization> nor the
 names of its contributors may be used to endorse or promote products
 derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 *********************************************************************************/

//
//  IGResizableComboBox.m
//

#import "IGResizableComboBox.h"

#define RESIZE_HANDLE_HEIGHT 5

#pragma mark -
#pragma mark Private helper class's interface
@interface IGResizableComboBoxPopUpContentView : NSView {
	NSComboBox *theComboBox;
}

@property(retain) NSComboBox *theComboBox;

//<#methods#>

@end


#pragma mark -
#pragma mark main class implementation

@implementation IGResizableComboBox

@synthesize isPopUpOpen;

IGResizableComboBoxPopUpContentView *innerView;

- (id)initWithFrame:(NSRect)frame {
//	NSLog(@"initWithFrame:");
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		[self awakeFromNib];
		[self setNumberOfVisibleItemsAutosaveName:nil];
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
												 name:@"NSComboBoxWillPopUpNotification"
											   object:self];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(willDismiss:)
												 name:@"NSComboBoxWillDismissNotification"
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
												 toView:[[self window] contentView]];
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

- (void)drawRect:(NSRect)dirtyRect {
    // Drawing code here.
	[super drawRect:dirtyRect];
	if ([self isPopUpOpen]) {
//		NSUInteger numberOfDisplayedLines = MIN([self numberOfVisibleItems],MAX(1,[self numberOfItems]));
		NSWindow *child = [self comboBoxPopUpWindow];
		if (child) {
			NSRect windowFrame = [child frame];
//			NSLog(@"window frame y: %f; self frame y in base coord: %f",
//				  windowFrame.origin.y,
//				  [[self window] convertBaseToScreen:[self frame].origin].y);
//			NSLog(@"window frame y in self window base: %f; self frame y: %f",
//				  [[self window] convertScreenToBase:windowFrame.origin].y,
//				  [self frame].origin.y);
			NSLog(@"pop-up is %@",[self isPopUpBelow] ? @"below" : ([self isPopUpAbove] ? @"above" : @"neither above nor below"));
			NSScrollView *scrollView = [child contentView];
			NSRect scrollViewFrame = [scrollView frame];
			
			windowFrame.size.height += RESIZE_HANDLE_HEIGHT;
			windowFrame.origin.y -= RESIZE_HANDLE_HEIGHT;
			scrollViewFrame.origin.y += RESIZE_HANDLE_HEIGHT;
			[child setFrame:windowFrame display:YES];
			
			innerView = [[IGResizableComboBoxPopUpContentView alloc] initWithFrame:scrollViewFrame];
			[innerView setTheComboBox:self];
			[child setContentView:innerView];
			[innerView addSubview:scrollView];
			[scrollView setFrame:scrollViewFrame];
		}
	} else {
	}
}

- (void)setNumberOfVisibleItems:(NSInteger)visibleItems
{
	[super setNumberOfVisibleItems:visibleItems];
	if (numberOfVisibleItemsAutosaveName) {
		[[NSUserDefaults standardUserDefaults] setInteger:visibleItems forKey:numberOfVisibleItemsAutosaveName];
	}
}

- (void)setNumberOfVisibleItemsAutosaveName:(NSString *)name
{
//	NSLog(@"changing combobox length autosave name from '%@' to '%@'",numberOfVisibleItemsAutosaveName,name);
	[numberOfVisibleItemsAutosaveName release];
	numberOfVisibleItemsAutosaveName = [name copy];
	[self setNumberOfVisibleItems:[[NSUserDefaults standardUserDefaults] integerForKey:numberOfVisibleItemsAutosaveName]];
}


- (void)willPopUp:(NSNotification *)notification
{
//	NSLog(@"willPopUp:");
	[self setIsPopUpOpen:YES];
}

- (void)willDismiss:(NSNotification *)notification
{
	NSScrollView *scrollView = [[innerView subviews] objectAtIndex:0];
	[[innerView window] setContentView:scrollView];
//	NSLog(@"willDismiss:");
	[self setIsPopUpOpen:NO];
}

@end


#pragma mark -
#pragma mark Private helper class's implementation

@implementation IGResizableComboBoxPopUpContentView

#define SIGNUM(f) ((f) / fabs(f))

@synthesize theComboBox;

CGFloat draggingBasisY;
BOOL draggingNow;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		draggingBasisY = 0.0;
		draggingNow = NO;
		[self setTheComboBox:nil];
    }
    return self;
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
		// if we're a bit more than half-way to a change of one item height, then we actually resize
		CGFloat delta_y = SIGNUM(draggingBasisY - newY) * realItemHeight;
		draggingBasisY -= delta_y;
		
		NSWindow *popup = [self window];
		NSRect windowFrame = [popup frame];
		CGFloat previousHeight = windowFrame.size.height;
		windowFrame.size.height = MAX(windowFrame.size.height + delta_y,RESIZE_HANDLE_HEIGHT + realItemHeight);
		delta_y = windowFrame.size.height - previousHeight;
		windowFrame.origin.y -= delta_y;
		[popup setFrame:windowFrame display:YES];
		
		NSInteger newNumberOfVisibleItems = round((windowFrame.size.height - RESIZE_HANDLE_HEIGHT)/realItemHeight);
		[theComboBox setNumberOfVisibleItems:newNumberOfVisibleItems];
	}
}

@end
