#import "SurvisualizerAppDelegate.h"
#import "EAGLView.h"
#import "Surface.h"

//------------------------------------------------------------------------------

@implementation SurvisualizerAppDelegate

@synthesize window;
@synthesize glView;

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	application.statusBarHidden = YES;
	id cameraController = [objc_getClass("PLCameraController") sharedInstance];
	[cameraController startPreview];
	[Surface dynamicLoad];
	[glView installCameraCallbackHook];
}

- (void)dealloc {
	[window release];
	[glView release];
	[super dealloc];
}

@end
