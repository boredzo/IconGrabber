#include <Carbon/Carbon.h>

enum { appSignature = 'ICON' };

OSStatus cmdHandler(EventHandlerCallRef nextHandler, EventRef event, void *refcon);

int main(void) {
    IBNibRef 		nibRef;
    WindowRef 		window;
    EventTypeSpec   cmdEvent = { kEventClassCommand, kEventCommandProcess };
    OSStatus		err;

    err = CreateNibReference(CFSTR("main"), &nibRef);
    require_noerr( err, CantGetNibRef );
    
    err = SetMenuBarFromNib(nibRef, CFSTR("MenuBar"));
    require_noerr( err, CantSetMenuBar );
    
    err = CreateWindowFromNib(nibRef, CFSTR("MainWindow"), &window);
    require_noerr( err, CantCreateWindow );

    DisposeNibReference(nibRef);
	
	//fill out controls.

	//first we put the system signature in the signature field.
	//the nib has 'macs' in there by default, which is the current system
	//  signature; however, if it changes, this makes it only require a
	//  recompile.
	ControlRef control = NULL;
	ControlID signatureID = { appSignature, 1100 };
	ControlID labelID     = { appSignature, 6000 };

	GetControlByID(window, &signatureID, &control);

	OSType type = kSystemIconsCreator;

	err = SetControlData(control, kControlEditTextPart, kControlEditTextTextTag, sizeof(type), &type);
	printf("SetControlData: %i\n", (int) err);

	//put the label names into the label pop-up.
	MenuRef labelMenu = NULL;

	GetControlByID(window, &labelID, &control);
	err = GetControlData(control, kControlMenuPart, kControlPopupButtonMenuRefTag, sizeof(labelMenu), &labelMenu, /*outActualSize*/ NULL);
	if(err == noErr) {
		MenuItemIndex i = 1;
		CFStringRef title = NULL;
		CFStringRef separator = CFSTR(": ");
		CFMutableStringRef mutableTitle;
		Str255 labelName;

		for(; i <= 7; ++i) {
			CopyMenuItemTextAsCFString(labelMenu, i, &title);
			if(title == NULL) break;

			mutableTitle = CFStringCreateMutableCopy(kCFAllocatorDefault, /*maxLen*/ 0, title);
			CFRelease(title);
			if(mutableTitle == NULL) break;

			CFStringAppend(mutableTitle, separator);

			GetLabel(i, /*outColor*/ NULL, labelName);
			CFStringAppendPascalString(mutableTitle, labelName, kCFStringEncodingMacRoman);

			SetMenuItemTextWithCFString(labelMenu, i, mutableTitle);
			CFRelease(mutableTitle);
		}
	}

	//done with controls.
	//set up us the event handlers.
	err = InstallWindowEventHandler(window, NewEventHandlerUPP(cmdHandler), GetEventTypeCount(cmdEvent), &cmdEvent, window, NULL);
    require_noerr( err, CantInstallHandler );

    ShowWindow( window );
    
    RunApplicationEventLoop();

CantCreateWindow:
CantInstallHandler:
CantSetMenuBar:
CantGetNibRef:
	return err;
}

SInt16  iconWidths[] = { 12, 16, 32, 48, 64, 128 };
SInt16 iconHeights[] = { 16, 16, 32, 48, 64, 128 };

OSStatus cmdHandler(EventHandlerCallRef nextHandler, EventRef event, void *refcon) {
#pragma unused(nextHandler)
	OSStatus err = eventNotHandledErr;
	UInt32 class = GetEventClass(event);
	
	if(class == kEventClassCommand) {
		UInt32 kind = GetEventKind(event);
		
		if(kind == kEventCommandProcess) {
			HICommand cmd;
			
			err = GetEventParameter(event, kEventParamDirectObject, typeHICommand, NULL, sizeof(cmd), NULL, &cmd);
			if(err == noErr) {
				switch(cmd.commandID) {
					case 'DRAW': {
						ControlID typeID      = { appSignature, 1000 };
						ControlID signatureID = { appSignature, 1100 };
						ControlID wellID      = { appSignature, 3000 };
						ControlID transformID = { appSignature, 4000 };
						ControlID selectedID  = { appSignature, 5000 };
						ControlID labelID     = { appSignature, 6000 };
						ControlID sizeID      = { appSignature, 7000 };
						/* ET = edit-text
						 * IW = image well
						 * PM = pop-up menu
						 * CB = check-box
						 * SL = slider
						 */
						ControlRef typeET      = NULL;
						ControlRef signatureET = NULL;
						ControlRef wellIW      = NULL;
						ControlRef transformPM = NULL;
						ControlRef selectedCB  = NULL;
						ControlRef labelPM     = NULL;
						ControlRef sizeET      = NULL;

						Str255 edittextvalue = "\p";
						OSType *edittexttype = (OSType *)&edittextvalue[1];
						OSType ostype = '\x3f\x3f\x3f\x3f'; //four ?s
						OSType signature = kSystemIconsCreator;
						SInt32 transformNum = 0;
						SInt32 selected = kControlCheckBoxUncheckedValue;
						SInt32 label = 0;
						SInt32 size = 2; //index into icon{Widths,Heights}

						WindowRef window = (WindowRef)refcon;
						Size len = 0U;
						IconRef icon;
						Rect drawRect;
						IconAlignmentType align = kAlignAbsoluteCenter;
						IconTransformType transform;

						fputs("Got DRAW command\n", stdout);

						fputs("Getting selector type\n", stdout);
						//get the selector type from the edit-text.
						err = GetControlByID(window, &typeID, &typeET);
						if(err != noErr)
							break;
						err = GetControlData(typeET, kControlEditTextPart, kControlEditTextTextTag, sizeof(edittextvalue) - 1, &edittextvalue[1], &len);
						if(err != noErr) break;

						//turn it into an OSType.
						//this is done by taking a pointer to its first
						//  character (== its first FOUR characters), and
						//  calling it an OSType pointer.
						if(len != 4U) {
							SysBeep(0);
							break;
						}
						edittextvalue[0] = 4U;
						ostype = *edittexttype;

						//select the entire contents of the edit-text.
						ControlEditTextSelectionRec selection;
						selection.selStart = 0;
						selection.selEnd   = 4;
						SetControlData(typeET, kControlEditTextPart, kControlEditTextSelectionTag, sizeof(selection), &selection);

						fputs("Getting signature\n", stdout);
						err = GetControlByID(window, &signatureID, &signatureET);
						if(err != noErr) break;
						err = GetControlData(signatureET, kControlEditTextPart, kControlEditTextTextTag, sizeof(edittextvalue) - 1, &edittextvalue[1], &len);
						if(err != noErr) break;
						
						//turn it into an OSType.
						//this is done by taking a pointer to its first
						//  character (== its first FOUR characters), and
						//  calling it an OSType pointer.
						if(len == 0U) {
							*edittexttype = signature;
							len = 4U;
						}
						if(len != 4U) {
							SysBeep(0);
							break;
						}
						edittextvalue[0] = 4U;
						signature = *edittexttype;

						fputs("Getting icon\n", stdout);
						//get the icon.
						err = GetIconRef(kOnAppropriateDisk, signature, ostype, &icon);
						if(err != noErr) break;

						fputs("Getting image-well rectangle\n", stdout);
						//obtain the existing image-well rectangle, so we can resize it.
						err = GetControlByID(window, &wellID, &wellIW);
						if(err != noErr)
							goto cantGetControl;
						GetControlBounds(wellIW, &drawRect);

						fputs("Getting target size\n", stdout);
						//obtain the target size (per side).
						err = GetControlByID(window, &sizeID, &sizeET);
						if(err != noErr)
							goto cantGetControl;
//						size = 'SIZ0' + GetControl32BitValue(sizeET);
//						err = GetControlProperty(sizeET, appSignature, size, sizeof(size), /*outActualSize*/ NULL, &size);
						CFStringRef sizeString = NULL;
						err = GetControlData(sizeET, kControlEditTextPart, kControlEditTextCFStringTag, sizeof(sizeString), &sizeString, /*outActualSize*/ NULL);
						if(err != noErr || sizeString == NULL)
							goto cantGetSizeConstant;

						size = CFStringGetIntValue(sizeString);
						CFRelease(sizeString);
						if(size == 0) {
							SysBeep(0L);
							size = 32;
						}

						fputs("Adjusting image well size\n", stdout);
						size /= 2;
						short center;

						center = (drawRect.right + drawRect.left) / 2;
						drawRect.left  = center - size;
						drawRect.right = center + size;

						center = (drawRect.bottom + drawRect.top) / 2;
						drawRect.top    = center - size;
						drawRect.bottom = center + size;

						//pad the rectangle by the size of the image well border.
						size = 0; //JIC
						GetThemeMetric(kThemeMetricImageWellThickness, &size);
						drawRect.top    -= size;
						drawRect.bottom += size;
						drawRect.left   -= size;
						drawRect.right  += size;

						SetControlBounds(wellIW, &drawRect);

						fputs("Getting transform\n", stdout);
						//get the transformation.
						err = GetControlByID(window, &transformID, &transformPM);
						if(err != noErr)
							goto cantGetControl;
						transformNum = GetControl32BitValue(transformPM);
						IconTransformType transformConstants[] = { kTransformNone, kTransformDisabled, kTransformOffline, kTransformOpen };
						transform = transformConstants[transformNum - 1];

						fputs("Getting selectedness\n", stdout);
						//modify as necessary for selection.
						err = GetControlByID(window, &selectedID, &selectedCB);
						if(err != noErr)
							goto cantGetControl;
						selected = GetControl32BitValue(selectedCB);
						if(selected != kControlCheckBoxUncheckedValue) {
							//checked
							transform |=  kTransformSelected;
						} else
							transform &= ~kTransformSelected;

						fputs("Getting label\n", stdout);
						//and for a label.
						IconTransformType allLabels = kTransformLabel1 | kTransformLabel2 | kTransformLabel3 | kTransformLabel4 | kTransformLabel5 | kTransformLabel6 | kTransformLabel7;
						transform &= ~allLabels;

						err = GetControlByID(window, &labelID, &labelPM);
						if(err != noErr)
							goto cantGetControl;
						label = GetControl32BitValue(labelPM);
						IconTransformType labels[] = { kTransformLabel1, kTransformLabel2, kTransformLabel3, kTransformLabel4, kTransformLabel5, kTransformLabel6, kTransformLabel7, 0, 0 };
						transform |= labels[label - 1];

#if 0
						fputs("Setting transform\n", stdout);
						//apply it.
						err = SetImageWellTransform(wellIW, transform);
						if(err != noErr)
							goto cantSetTransform;

						//put in the image.
						printf("Drawing image\n");
						struct ControlButtonContentInfo cbci;
						cbci.contentType = kControlContentIconRef;
						cbci.u.iconRef   = icon;
						err = SetImageWellContentInfo(wellIW, &cbci);
						if(err != noErr)
							goto cantSetIcon;
#endif
						//draw the background.
						DrawOneControl(wellIW);

						//un-adjust the rectangle before drawing.
						drawRect.top    += size;
						drawRect.bottom -= size;
						drawRect.left   += size;
						drawRect.right  -= size;

						CGrafPtr port;
						GDHandle device;
						GetGWorld(&port, &device);
						SetPortWindowPort(window);

						err = PlotIconRef(&drawRect, align, transform, kIconServicesNormalUsageFlag, icon);
						printf("PlotIconRef: %i\n", (int) err);

						SetGWorld(port, device);
cantSetIcon:
cantSetTransform:
cantGetSizeConstant:
cantGetControl:
						ReleaseIconRef(icon);
						break;
					} //case 'DRAW'
					case 'INCR': {
						//little arrows
						ControlRef control;
						ControlID arrowsID = { appSignature, 7100 };
						ControlID   sizeID = { appSignature, 7000 };
						WindowRef window = (WindowRef)refcon;

						err = GetControlByID(window, &arrowsID, &control);
						printf("GBCI (arrows): %i\n", (int) err);

						SInt32 value = GetControl32BitValue(control);
						printf("GC32BV (arrows): %i\n", (int) value);
						float fvalue = value ? value : 0.5f;

						err = GetControlByID(window, &sizeID, &control);
						printf("GBCI (edit-text): %i\n", (int) err);

						Str255 string;

						NumToString(32L * fvalue, string);
						err = SetControlData(control, kControlEditTextPart, kControlEditTextTextTag, *string, &string[1]);
						printf("SCD: %i\n", (int) err);

						break;
					}						
					default:
						err = eventNotHandledErr;
				} //switch(cmd.commandID)
			} //if(err == noErr): GetEventParameter
		} //if(kind == kEventCommandProcess)
	} //if(class == kEventClassCommand)
	
	return err;
} //OSStatus cmdHandler(EventHandlerCallRef nextHandler, EventRef event, void *refcon)
