#import "SurvisualizerAppDelegate.h"
#import "EAGLView.h"
#import "Surface.h"

//------------------------------------------------------------------------------

@implementation SurvisualizerAppDelegate

@synthesize window;
@synthesize glView;
@synthesize caView;

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	application.statusBarHidden = YES;
	id cameraController = [objc_getClass("PLCameraController") sharedInstance];
	[cameraController startPreview];
	[Surface dynamicLoad];
	glView.caView = caView;
	[glView installCameraCallbackHook];
}

- (void)dealloc {
	[window release];
	[glView release];
	[caView release];
	[super dealloc];
}

- (IBAction)toggleView:(id)sender {
	static BOOL caIsHidden = YES;

	caIsHidden = !caIsHidden;
	glView.hidden = !caIsHidden;
	caView.hidden = caIsHidden;

	if (caIsHidden) {
		[sender setBackgroundColor:[UIColor whiteColor]];
	} else {
		[sender setBackgroundColor:[UIColor magentaColor]];
	}
}

@end
