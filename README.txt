IconGrabber 2.0

Concept
=======

An application that wraps the Icon Services and NSImage APIs, allowing you to retrieve an icon by type and creator, name, filename extension, or MIME type, apply various transformations to it, and then look at in an image well and optionally save or copy it.

Usage
=====

First you must specify a criterion by which to look up the icon. There are four:

* Type and creator
	You can use any of the file type constants in HIServices/Icons.h (in which case the creator field should be either left blank or set to 'kSystemIconsCreator' or 'macs'), or any valid type and creator (for example, GIFf/prvw will show you Preview's icon for a GIF file).
* Name
	Any name that NSImage's +imageNamed: method will accept will work. This means any TIFF image in /System/Library/AppKit.framework/Resources, minus the filename extension.
* Extension
	Any filename extension. You can give as many leading periods (zero or more) as you like; they will be stripped off for the look-up.
* MIME type
	You can find a central repository of these (used by Apache web server) in /etc/httpd/mime.types; you can also look inside applications' Icon.plist files using a text editor or Property List Editor to see what MIME types they support.

On Jaguar, extension and MIME-type look-up are not available, therefore you can only look up icons by type/creator or name.

Three of those criteria are looked up through Icon Services (name lookups aren't available in Icon Services; they're done with NSImage). For these criteria, you can specify transformations to apply to the image:

* Transform
	'Disabled' makes it look like a disabled control. 'Offline' is what used to happen to a disk when you unmounted it without ejecting it (now, as of Panther, it has no effect). 'Open' is what used to happen to an application when you opened it (now, as of Panther, it makes the icon disappear!).
* Selected
	Darkens the image, like when you select it in the Finder.
* Width/height
	Scales the image to this size. Usually, several source images are available, and the system libraries pick the closest one for fidelity.
* Label
	A color with which to tint the image. This can be 'None', 'Custom' (use the color in the color well to the left of the pop-up), or any of the seven predefined label colors.

When all is set up, click 'Draw'. IconGrabber will summon the icon and render it in the image well. If no icon was found, Icon Services returns a document icon whereas NSImage returns no image.

You can resize the window to adjust the size of the image well and some of the fields and pop-ups; it will never, however, be displayed at a larger size than you specified in the width and height fields.

Version history
===============
2.0
---
* Changed version to 2.0 from 2.0b1.
* Added Get Info version for English users.

There were no code changes in 2.0. The only reason for the beta was to prove that everything (including auto-disabling of extension and MIME type) works on Jaguar.

2.0b1
-----
* Added ability to get icons by name, using AppKit's +[NSImage imageNamed:] method.
* Added ability to get icons by MIME type or pathname extension, using Icon Services' GetIconRefFromTypeInfo. Automatically disabled on OS X < 10.3.
* Fixed memory leak of IconRefs in 1.0.
* Separated IconRef->NSImage code from the get-by-type-and-creator code (since the get-by-MIME-type and get-by-extension methods use it too).
* Separated Size field into Width and Height fields. It is now possible to scale the icon so that it is not square.
* Fixed bug wherein the steppers ignored the value in their respective fields, so that if you changed the value in the field, then operated the stepper, the stepper would go to the next or previous step from the old size value.
* The IconGrabber window is now centered on startup, and remembers its position and size for future startups.
* Added tool-tips.

1.0
---
Initial release.

Future expansion
----------------
* Provide an option to open a file to get its icon or to read an image from it.
* Provide a command to open any bundle, and extend the by-name look-up to search in those bundles. Alternatively, allow the user to specify a single secondary bundle in which to look for images.
* Allow drag-and-drop onto the type and creator fields.

Contact; date
=============

http://boredzo.fourx.org/icongrabber/

This software was released on 2004-11-23.
