//
//  IconGrabber.h
//  IconGrabber
//
//  Created by Mac-arena the Bored Zo on 08/15/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

enum {
	useTypeCreator,
	useName,
	useExtension,
	useMIMEType,
};

@interface IconGrabber: NSObject
{
	unsigned char *imageBacking;
	//currently we don't use this as an actual cache; the image is regenerated
	//	any time 'Draw' is hit.
	//in the future, we may have some way to mark the image as dirty whenever
	//	one of the control values is changed, and only regenerate when that bit
	//	is set.
	NSImage *cachedImage;

	NSString *saveDirectory;
	NSString *savePath;
	NSString *defaultFilename;

	IBOutlet NSTextField	*typeField, *creatorField;
	IBOutlet NSTextField	*nameField;
	IBOutlet NSTextField	*extField;
	IBOutlet NSTextField	*MIMEField;
	IBOutlet NSPopUpButton	*transformPopup;
	IBOutlet NSButton		*selectedCheckbox;
	IBOutlet NSTextField	*widthField, *heightField;
	IBOutlet NSColorWell	*labelWell;
	IBOutlet NSPopUpButton	*labelPopup;
	IBOutlet NSButton		*drawButton;
	IBOutlet NSImageView	*imageWell;
	IBOutlet NSWindow		*mainWindow;
	IBOutlet NSMatrix		*modeButtons;
}

- (NSImage *)imageWithHFSType:(NSString *)typeString creator:(NSString *)creatorString;
- (NSImage *)imageWithPathExtension:(NSString *)ext;
- (NSImage *)imageWithMIMEType:(NSString *)type;
- (NSImage *)imageWithName:(NSString *)name;

- (NSImage *)imageWithCarbonIcon:(IconRef)icon;

- (IBAction)updateEnabledStates:sender;
- (IBAction)drawIcon:sender;

- (IBAction)setLabelPopUpToCustom:sender;

- (IBAction)copyImage:sender;
- (IBAction)saveDocument:sender;
- (IBAction)saveDocumentAs:sender;
//- (IBAction)saveImageAsLast:sender;
//- (IBAction)saveImageAs:sender;

- (BOOL)saveImage:(NSImage *)image toPath:(NSString *)path atomically:(BOOL)atomically;

@end
