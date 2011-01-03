===================
IGResizableComboBox
===================

*An NSComboBox subclass that adds a small draggable bar to allow drag-resizing of the pop-up list.*

**Inner Workings**

NSComboBox generates its pop-up by creating a special NSWindow subclass, NSComboBoxWindow. This pop-up window has an NSScrollView (or subclass thereof) as its content view and uses that to display the choices and (if needed) the scrollbar (via an NSComboTableView, which is a subclass of NSTableView).

IGResizableComboBox inserts its own NSView subclass as the content view of the NSComboBoxWindow and puts the NSScrollView as a subview of this NSView. This NSView is slightly taller than the NSScrollView and the NSView captures mouse dragging events on this extra space to allow resizing.

(The issue related to whether the pop-up was above or below the NSComboBox is resolved as of r20:408e5cd05064.)



----

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
