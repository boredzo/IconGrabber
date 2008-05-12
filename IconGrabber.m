//
//  IconGrabber.m
//  IconGrabber
//
//  Created by Peter Hosey on 08/15/2004.
//  Copyright 2004 Peter Hosey. All rights reserved.
//

#import "IconGrabber.h"
#import "IGStringAdditions.h"

static const IconTransformType transforms[] = { kTransformNone, kTransformDisabled, kTransformOffline, kTransformOpen };
//map pop-up menu indices to label indices. (see docs for GetLabel in Icon Utilities.)
static const SInt16 labels[] = { 0, 0, 1, 2, 3, 4, 5, 6, 7 };

static NSString *systemCreatorName = @"kSystemIconsCreator";
static NSString *filenameExtension = @"tiff";

@implementation IconGrabber

- init {
	self = [super init];
	if(self) {
		saveDirectory = [NSHomeDirectory() retain];
		defaultFilename = [[NSLocalizedString(@"Default filename", /*comment*/ NULL) stringByAppendingPathExtension:filenameExtension] retain];
	}
	return self;
}

- (NSImage *)imageWithHFSType:(NSString *)typeString creator:(NSString *)creatorString {
	OSStatus err;
	char cString[8]; //8 for alignment
	OSType fileType, creator;
	if([typeString length] == 4U) {
		unsigned creatorLength = [creatorString length];
		
		if(creatorLength == 4U) {
			CFStringGetCString((CFStringRef)creatorString, cString, 8, kCFStringEncodingMacRoman);
			creator = *(OSType *)cString;
		} else if((creatorLength == 0U) || [creatorString isEqualToString:systemCreatorName]) {
			creator = kSystemIconsCreator;
		} else {
			[[creatorField window] makeFirstResponder:creatorField];
			NSRunAlertPanel(NSLocalizedString(@"Invalid signature", /*comment*/ NULL),
							NSLocalizedString(@"Signatures must be four MacRoman characters.", /*comment*/ NULL),
							NSLocalizedString(@"OK", /*comment*/ NULL), nil, nil);
			return nil;
		}
		CFStringGetCString((CFStringRef)typeString, cString, 8, kCFStringEncodingMacRoman);
		fileType = *(OSType *)cString;
	} else /*if([typeString length] != 4U)*/ {
		[[typeField window] makeFirstResponder:typeField];
		if([creatorString length] == 4U)
			NSRunAlertPanel(NSLocalizedString(@"Invalid file type", /*comment*/ NULL),
							NSLocalizedString(@"File types must be four MacRoman characters.", /*comment*/ NULL),
							NSLocalizedString(@"OK", /*comment*/ NULL), nil, nil);
		else //if([creatorString length] != 4U)
			NSRunAlertPanel(NSLocalizedString(@"Invalid file type and signature", /*comment*/ NULL),
							NSLocalizedString(@"File types and signatures must be four MacRoman characters.", /*comment*/ NULL),
							NSLocalizedString(@"OK", /*comment*/ NULL), nil, nil);
		return nil;
	}
	IconRef icon;

	err = GetIconRef(kOnSystemDisk, creator, fileType, &icon);
	if(!icon) {
		NSRunAlertPanel(NSLocalizedString(@"Icon Services error", /*comment*/ NULL),
						[NSString stringWithFormat:NSLocalizedString(@"GetIconRef did not return an IconRef: err %li", /*comment*/ NULL), (long)err],
						NSLocalizedString(@"OK", /*comment*/ NULL), nil, nil);
		return nil;
	}

	NSImage *image = [self imageWithCarbonIcon:icon];
	ReleaseIconRef(icon);
	return image;
}
- (NSImage *)imageWithPathExtension:(NSString *)ext {
	IconRef icon;
	OSStatus err = GetIconRefFromTypeInfo(/*creator*/ 0, /*type*/ 0, (CFStringRef)ext, /*MIMEType*/ NULL, kIconServicesNormalUsageFlag, &icon);
	if(!icon) {
		NSRunAlertPanel(NSLocalizedString(@"Icon Services error", /*comment*/ NULL),
						[NSString stringWithFormat:NSLocalizedString(@"GetIconRef did not return an IconRef: err %li", /*comment*/ NULL), (long)err],
						NSLocalizedString(@"OK", /*comment*/ NULL), nil, nil);
		return nil;
	}

	NSImage *image = [self imageWithCarbonIcon:icon];
	ReleaseIconRef(icon);
	return image;
}
- (NSImage *)imageWithMIMEType:(NSString *)type {
	IconRef icon;
	OSStatus err = GetIconRefFromTypeInfo(/*creator*/ 0, /*type*/ 0, /*extension*/ NULL, (CFStringRef)type, kIconServicesNormalUsageFlag, &icon);
	if(!icon) {
		NSRunAlertPanel(NSLocalizedString(@"Icon Services error", /*comment*/ NULL),
						[NSString stringWithFormat:NSLocalizedString(@"GetIconRef did not return an IconRef: err %li", /*comment*/ NULL), (long)err],
						NSLocalizedString(@"OK", /*comment*/ NULL), nil, nil);
		return nil;
	}
	
	NSImage *image = [self imageWithCarbonIcon:icon];
	ReleaseIconRef(icon);
	return image;
}

- (NSImage *)imageWithCarbonIcon:(IconRef)icon {
	AcquireIconRef(icon);

	OSStatus err;
	IconTransformType transform = transforms[[transformPopup indexOfItem:[transformPopup selectedItem]]];
	transform |= kTransformSelected * ([selectedCheckbox state] != NSOffState);
	RGBColor labelColor, *labelColorPtr;
	SInt16 labelIndex = [labelPopup indexOfItem:[labelPopup selectedItem]];
	switch(labelIndex) {
		case 0:
			//no label
			labelColorPtr = NULL;
			break;
		case 1:;
			//custom label (read from colorWell)
			NSColor *color = [[labelWell color] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
			float r, g, b;
			[color getRed:&r green:&g blue:&b alpha:NULL];
			enum { COLOR_MAX = SHRT_MAX };
			labelColor.red   = COLOR_MAX * r;
			labelColor.green = COLOR_MAX * g;
			labelColor.blue  = COLOR_MAX * b;
			labelColorPtr = &labelColor;
			break;
		default:;
			Str255 labelName;
			GetLabel(labels[labelIndex], &labelColor, labelName);
			labelColorPtr = &labelColor;
	}
	PlotIconRefFlags flags = kPlotIconRefNormalFlags;
	IconAlignmentType align = kAlignAbsoluteCenter;

	size_t width, height;
	//we use floatValue because it accomodates the added range of an unsigned
	//	int; intValue does not (it is signed).
	width  = [widthField  floatValue];
	height = [heightField floatValue];
	if(!width && !height) {
		//size is 0: find largest size and use that
		/*	Thumbnail: 128
		 *	Huge: 48
		 *	Large: 32
		 *	Small: 16
		 *	Mini: 8
		 */
		//only use IsDataAvailableInIconRef on 10.3 and later.
		//on earlier versions, use now-deprecated GetIconSizesFromIconRef.
		if(IsDataAvailableInIconRef) {
			if(IsDataAvailableInIconRef(kThumbnail32BitData, icon))
				width = height = 128U;
			else if(IsDataAvailableInIconRef(kHuge32BitData, icon)
				|| IsDataAvailableInIconRef(kHuge8BitData, icon)
				|| IsDataAvailableInIconRef(kHuge4BitData, icon))
				width = height = 48U;
			else if(IsDataAvailableInIconRef(kLarge32BitData, icon)
				|| IsDataAvailableInIconRef(kLarge8BitData, icon)
				|| IsDataAvailableInIconRef(kLarge4BitData, icon))
				width = height = 32U;
			else if(IsDataAvailableInIconRef(kSmall32BitData, icon)
				|| IsDataAvailableInIconRef(kSmall8BitData, icon)
				|| IsDataAvailableInIconRef(kSmall4BitData, icon))
				width = height = 16U;
			else if(IsDataAvailableInIconRef(kMini8BitData, icon)
				|| IsDataAvailableInIconRef(kMini4BitData, icon))
				width = height = 8U;
			else //default to 128
				width = height = 128U;
		} else if(GetIconSizesFromIconRef) {
			enum {
				imageDataMask = (kSelectorAllHugeData | kSelectorAllLargeData | kSelectorAllSmallData | kSelectorAllMiniData) & ~(kSelectorHuge8BitMask | kSelectorLarge8BitMask | kSelectorSmall8BitMask)
			};
			IconSelectorValue selectors = 0U;
			err = GetIconSizesFromIconRef(imageDataMask, &selectors, kIconServicesNormalUsageFlag, icon);
			if(err != noErr) //default to 128 on error
				width = height = 128U;
			else if(selectors & kSelectorAllHugeData)
				width = height = 48U;
			else if(selectors & kSelectorAllLargeData)
				width = height = 32U;
			else if(selectors & kSelectorAllSmallData)
				width = height = 16U;
			else if(selectors & kSelectorAllMiniData)
				width = height = 8U;
		} else {
			//this version of IconGrabber doesn't know how to determine the
			//	largest size on this OS version.
			//fall back on 128.
			width = height = 128U;
		}
	}
	CGRect drawRect = { { 0.0f, 0.0f }, { width, height } };
	const size_t bitsPerComponent = 8U;
	size_t bytesPerRow = width * 4U; //4 bytes per pixel

	free(imageBacking);
	imageBacking = calloc(width * height, 4U /*4 bytes per pixel*/);

	NSBitmapImageRep *bitmapRep = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&imageBacking
																		   pixelsWide:width
																		   pixelsHigh:height
																		bitsPerSample:bitsPerComponent
																	  samplesPerPixel:4
																			 hasAlpha:YES
																			 isPlanar:NO
																	   colorSpaceName:NSDeviceRGBColorSpace
																		  bytesPerRow:0
																		 bitsPerPixel:0] autorelease];

	CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
	if(rgb) {
		CGImageAlphaInfo alpha = kCGImageAlphaPremultipliedLast;
		CGContextRef context = CGBitmapContextCreate(imageBacking, width, height, bitsPerComponent, bytesPerRow, rgb, alpha);
		if(context) {
			PlotIconRefInContext(context, &drawRect, align, transform, labelColorPtr, flags, icon);
			CGContextRelease(context);
		}
		CGColorSpaceRelease(rgb);
	}
	ReleaseIconRef(icon);

	NSArray *representations = [NSArray arrayWithObject:bitmapRep];
	NSSize *imageSize = (NSSize *)&drawRect.size;
	NSImage *image = [[NSImage alloc] initWithSize:*imageSize];
//	NSSize imageActualSize = [image size];
	[image addRepresentations:representations];
	return [image autorelease];
}

- (NSImage *)imageWithName:(NSString *)name {
	NSImage *icon = [NSImage imageNamed:name];
	float width = [widthField floatValue], height = [heightField floatValue];
	if(width && height) {
		NSSize size = { width, height };
		[icon setScalesWhenResized:YES];
		[icon setSize:size];
	}
	return icon;
}

- (IBAction)updateEnabledStates:sender {
	int tag = [[sender selectedCell] tag];
	BOOL iconServicesControlsEnabled = (tag != useName);

	[typeField    setEnabled: tag == useTypeCreator];
	[creatorField setEnabled: tag == useTypeCreator];
	[nameField    setEnabled: tag == useName];
	[extField     setEnabled: tag == useExtension];
	[MIMEField    setEnabled: tag == useMIMEType];

	[transformPopup   setEnabled:iconServicesControlsEnabled];
	[selectedCheckbox setEnabled:iconServicesControlsEnabled];
	[labelWell        setEnabled:iconServicesControlsEnabled];
	[labelPopup       setEnabled:iconServicesControlsEnabled];
}
- (IBAction)drawIcon:sender {
#pragma unused(sender)
	NSString *typeString, *creatorString, *name;

	[cachedImage release];
	cachedImage = nil;

	int tag = [[modeButtons selectedCell] tag];
	if(tag == useTypeCreator) {
		typeString    = [typeField    stringValue];
		creatorString = [creatorField stringValue];
		cachedImage = [[self imageWithHFSType:typeString creator:creatorString] retain];
		if(cachedImage) {
			if([creatorString length] == 0U)
				defaultFilename = [[[typeString stringByEscapingPathSeparators] stringByAppendingPathExtension:filenameExtension] retain];
			else
				defaultFilename = [[[[NSString stringWithFormat:@"%@-%@", typeString, creatorString] stringByEscapingPathSeparators] stringByAppendingPathExtension:filenameExtension] retain];
		}
	} else if(tag == useExtension) {
		NSCharacterSet *dotSet = [NSCharacterSet characterSetWithCharactersInString:@"."];
		name = [[extField stringValue] stringByTrimmingCharactersInSet:dotSet];
		cachedImage = [[self imageWithPathExtension:name] retain];
		if(cachedImage)
			defaultFilename = [[[name stringByEscapingPathSeparators] stringByAppendingPathExtension:filenameExtension] retain];
	} else if(tag == useMIMEType) {
		name = [MIMEField stringValue];
		cachedImage = [[self imageWithMIMEType:name] retain];
		if(cachedImage)
			defaultFilename = [[[name stringByEscapingPathSeparators] stringByAppendingPathExtension:filenameExtension] retain];
	} else if(tag == useName) {
		name = [nameField stringValue];
		cachedImage = [[self imageWithName:name] retain];
		if(cachedImage)
			defaultFilename = [[[name stringByEscapingPathSeparators] stringByAppendingPathExtension:filenameExtension] retain];
	}
	[imageWell setImage:cachedImage];
	[imageWell setNeedsDisplay:YES];
}

- (IBAction)setLabelPopUpToCustom:sender {
#pragma unused(sender)
	[labelPopup selectItemAtIndex:1];
}

- (IBAction)copyImage:sender {
#pragma unused(sender)
	NSData *imageData = [[imageWell image] TIFFRepresentation];
	if(imageData) {
		NSPasteboard *pb = [NSPasteboard generalPasteboard];
		[pb declareTypes:[NSArray arrayWithObject:NSTIFFPboardType] owner:self];
		[pb setData:imageData forType:NSTIFFPboardType];
	}
}

- (IBAction)saveDocument:sender {
	if(savePath)
		[self saveImage:cachedImage toPath:savePath atomically:YES];
	else
		[self saveDocumentAs:sender];
}
- (IBAction)saveDocumentAs:sender {
#pragma unused(sender)
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	[savePanel setCanSelectHiddenExtension:YES];
	[savePanel beginSheetForDirectory:saveDirectory
								 file:defaultFilename
					   modalForWindow:mainWindow
						modalDelegate:self
					   didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:)
						  contextInfo:NULL];
}

- (void)savePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
#pragma unused(contextInfo)
	if(returnCode == NSOKButton) {
		[saveDirectory release];
		saveDirectory = [[sheet directory] retain];
		[savePath release];
		savePath = [[sheet filename] retain];
		[self saveImage:cachedImage toPath:savePath atomically:YES];
	}
}
- (BOOL)saveImage:(NSImage *)image toPath:(NSString *)path atomically:(BOOL)atomically {
	return [[image TIFFRepresentation] writeToFile:path atomically:atomically];
}

#pragma mark -
#pragma mark NSApplication delegate conformance

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
#pragma unused(notification)
	if(!GetIconRefFromTypeInfo) {
		//can't get icons by MIME type or path extension on this OS.
		//so, disable those buttons and fields.
		[[modeButtons cellWithTag:useExtension] setEnabled:NO];
		[extField setEnabled:NO];
		[[modeButtons cellWithTag:useMIMEType]  setEnabled:NO];
		[MIMEField setEnabled:NO];
	}
	[mainWindow setFrameUsingName:@"Main Window"];
	[mainWindow makeKeyAndOrderFront:self];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)app {
#pragma unused(app)
	return YES;
}

@end
