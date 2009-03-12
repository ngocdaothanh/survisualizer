#import "SurvisualizerAppDelegate.h"
#import "EAGLView.h"
#import "Surface.h"

//------------------------------------------------------------------------------

@implementation SurvisualizerAppDelegate

@synthesize window;
@synthesize glView;

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	application.statusBarHidden = YES;

	[glView installCameraCallbackHook];
}

- (void)dealloc {
	[window release];
	[glView release];
	[super dealloc];
}

@end
