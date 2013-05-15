Slide-Drawer
============
iOS category for UINavigationController which enables a view belonging to a UINavigationController to act as a drawer.

Slide Drawer is a simple drawer implementation which takes a screenshot of the current view controller, pushes the "bottom" drawer view controller into view, and overlays the screenshot of the previous view controller to simulate a drawer. The drawer can slide along 4 different directions(up, down, left, and right).

The drawer follows 

Adding SlideDrawer to your project:
==================================
Just add the following files to your project.<br/>
- UINavigationController+PPSlideDrawer.h<br/>
- UINavigationController+PPSlideDrawer.m<br/>
- PPSlideDrawerDelegate.h<br/>

Example of how PPSlideDrawer is used:
=====================================
This is an example project, so see MainViewController.m in project...

TODO
====
- Implement auto open functionality
- Implement swipe from edge functionality(rather than just detect panning gesture).

License
=======
```
//
//  Copyright (c) 2013 Patrick Pierson
//  
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
//  INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
//  PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
//  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
//  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

```
