#import "SurvisualizerAppDelegate.h"
#import "EAGLView.h"

#import "Surface.h"
#import "SurfaceAccelerator.h"

#import "Net.h"

static FUNC_camera_callback original_camera_callback = NULL;
static void *readblePixels = NULL;

static Net *net;

static int __camera_callbackHook(CameraDeviceRef cameraDevice, int a, CoreSurfaceBufferRef coreSurfaceBuffer, int b) {
	CoreSurfaceAcceleratorRef coreSurfaceAccelerator = *(CoreSurfaceAcceleratorRef*)(cameraDevice+84);
	unsigned int surfaceId = [Surface CoreSurfaceBufferGetID:coreSurfaceBuffer];
	if (coreSurfaceBuffer) {
		Surface *surface = [[Surface alloc]initWithCoreSurfaceBuffer:coreSurfaceBuffer];
		[surface lock];
		unsigned int height = surface.height;
		unsigned int width = surface.width;
		
		unsigned int bytesPerRow = surface.bytesPerRow;
		void *pixels = surface.baseAddress;
		/*
		 for (unsigned int j = 0; j < height; j++) {
		 memcpy(readblePixels + alignmentedBytesPerRow * j, pixels + bytesPerRow * j, bytesPerRow);
		 }
		 */
		
		uint8_t image[width*height];
		for (unsigned int j = 0; j < height; j++) {
			for (int i = 0; i < width; i++) {
				image[j*width + i] = ((uint8_t *) pixels)[bytesPerRow*j + i*4 + 1];  // Green channel
			}
		}
		
		[net broadcast:image size:width*height];
		
		[surface unlock];
		[surface release];
	}
	return (*original_camera_callback)(cameraDevice, a, coreSurfaceBuffer, b);
}

//------------------------------------------------------------------------------

@implementation SurvisualizerAppDelegate

@synthesize window;
@synthesize glView;

- (void)install_camera_callbackHook {
	id cameraController = [objc_getClass("PLCameraController") sharedInstance];
	char *p = NULL;
	object_getInstanceVariable(cameraController, "_camera", (void**) &p);
	if (!p) return;
	
	if (!original_camera_callback) {
		FUNC_camera_callback *funcP = (FUNC_camera_callback*) p;
		original_camera_callback = *(funcP+37);
		(funcP + 37)[0] = __camera_callbackHook;
	}
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	net = [[Net alloc] init];
	[net setPort:1225];
    NSError * startError = nil;
    [net setType:@"_cocoaecho._tcp."];
    if (![net start:&startError] ) {
        NSLog(@"Error starting server: %@", startError);
    } else {
        NSLog(@"Starting server on port %d", [net port]);
    }
	
	//application.statusBarHidden = YES;
	id cameraController = [objc_getClass("PLCameraController") sharedInstance];
	[cameraController startPreview];
	[Surface dynamicLoad];
	[self install_camera_callbackHook];
	
	glView.animationInterval = 1.0 / 60.0;
	[glView startAnimation];
}

- (void)applicationWillResignActive:(UIApplication *)application {
	glView.animationInterval = 1.0 / 5.0;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	glView.animationInterval = 1.0 / 60.0;
}

- (void)dealloc {
	[window release];
	[glView release];
	[super dealloc];
}

@end
