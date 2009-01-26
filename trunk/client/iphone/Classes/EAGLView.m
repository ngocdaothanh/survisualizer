#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>

//------------------------------------------------------------------------------

#import "EAGLView.h"
#import "Surface.h"
#import "SurfaceAccelerator.h"

#define USE_DEPTH_BUFFER 0

@interface EAGLView()
- (BOOL)createFramebuffer;
- (void)destroyFramebuffer;

- (void)onViewingFields:(NSInputStream *)istream;
- (void)onPose:(NSInputStream *)istream;
@end

//------------------------------------------------------------------------------

static FUNC_camera_callback original_camera_callback = NULL;

static uint8_t *frame  = NULL;
static int frameWidth  = 0;
static int frameHeight = 0;

static int __camera_callbackHook(CameraDeviceRef cameraDevice, int a, CoreSurfaceBufferRef coreSurfaceBuffer, int b) {
	if (coreSurfaceBuffer) {
		Surface *surface = [[Surface alloc]initWithCoreSurfaceBuffer:coreSurfaceBuffer];
		[surface lock];

		//[glView drawView:surface.baseAddress withWidth:surface.width withHeight:surface.height];
		if (!frame) {
			frameWidth  = surface.width;
			frameHeight = surface.height;
			frame = malloc(frameWidth*frameHeight*4);
		}
		memcpy(frame, surface.baseAddress, frameWidth*frameHeight*4);

		[surface unlock];
		[surface release];
	}
	return (*original_camera_callback)(cameraDevice, a, coreSurfaceBuffer, b);
}

//------------------------------------------------------------------------------

@implementation EAGLView

@synthesize m1;
@synthesize m2;
@synthesize m3;
@synthesize m4;
@synthesize m5;

+ (Class)layerClass {
	return [CAEAGLLayer class];
}

- (id)initWithCoder:(NSCoder*)coder {
	if ((self = [super initWithCoder:coder])) {
		// Get the layer
		CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;

		eaglLayer.opaque = YES;
		eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
										[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
		
		context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
		if (!context || ![EAGLContext setCurrentContext:context]) {
			[self release];
			return nil;
		}

		pose = [[Pose alloc] init];

		// Setup net
		net = [[Net alloc] initWithView:self];
		[net setPort:1225];
		NSError * startError = nil;
		[net setType:@"_survisualizer._tcp."];
		if (![net start:&startError] ) {
			NSLog(@"Error starting server: %@", startError);
		} else {
			NSLog(@"Started server on port %d", [net port]);
		}
	}
	return self;
}

/**
 * Called by SurvisualizerAppDelegate's applicationDidFinishLaunching because
 * PLCameraController is only available after UIImagePickerController has been
 * loaded.
 */
- (void)installCameraCallbackHook {
	id cameraController = [objc_getClass("PLCameraController") sharedInstance];
	char *p = NULL;
	object_getInstanceVariable(cameraController, "_camera", (void**) &p);
	if (!p) return;
	
	if (!original_camera_callback) {
		FUNC_camera_callback *funcP = (FUNC_camera_callback*) p;
		original_camera_callback = *(funcP+37);
		(funcP + 37)[0] = __camera_callbackHook;
	}

	// __camera_callbackHook runs in the application's main thread. If we
	// run the OpenGL drawing in this thread, the touch screen will become
	// unresponsive.
	textureInitialized = NO;
	backingWidth  = 0;
	backingHeight = 0;
	[NSThread detachNewThreadSelector:@selector(drawViewLoop:) toTarget:self withObject:nil];
}

- (void)drawViewLoop:(id)object {
	while (TRUE) {
		if (!textureInitialized && backingWidth != 0 && backingHeight != 0 && frameWidth != 0 && frameHeight != 0) {
			glGenTextures(1, &texture);
			glBindTexture(GL_TEXTURE_2D, texture);

			// Texture dimensions must be a power of 2
			textureWidth  = 512;
			textureHeight = 512;
			texturePixels = malloc(textureWidth*textureHeight*4);
			textureInitialized = YES;

			textureVertices[0] = 0;             textureVertices[1] = 0;
			textureVertices[2] = backingWidth;  textureVertices[3] = 0;
			textureVertices[4] = 0;             textureVertices[5] = backingHeight;
			textureVertices[6] = backingWidth;  textureVertices[7] = backingHeight;
			
			textureCoords[0] = 0;                                  textureCoords[1] = 0;
			textureCoords[2] = (GLfloat) frameWidth/textureWidth;  textureCoords[3] = 0;
			textureCoords[4] = 0;                                  textureCoords[5] = (GLfloat) frameHeight/textureHeight;
			textureCoords[6] = (GLfloat) frameWidth/textureWidth;  textureCoords[7] = (GLfloat) frameHeight/textureHeight;
			
			textureInitialized = YES;
		}

		if (frame) {
			NSAutoreleasePool* pool = [[NSAutoreleasePool alloc]init];
			[self drawView];
			[pool release];
		}
	}
	[NSThread exit];
}

- (void)drawView {
	[EAGLContext setCurrentContext:context];
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);

	// Viewport must be called everytime, don't know why
	glViewport(0, 0, backingWidth, backingHeight);

	// Draw background ---------------------------------------------------------
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glOrthof(0, backingWidth, 0, backingHeight, -1, 1);
	
	glMatrixMode(GL_MODELVIEW);
	glClearColorx(255, 255, 255, 255);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	glLoadIdentity();
	
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);  // Set the texture parameters to use a minifying filter and a linear filer (weighted average)
	glEnable(GL_TEXTURE_2D);										   // Enable use of the texture
	glDisable(GL_BLEND);                                               // Background doesn't need blending
	
	glTexCoordPointer(2, GL_FLOAT, 0, textureCoords);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	for (int j = 0; j < frameHeight; j++) {
		memcpy(texturePixels + j*textureWidth*4, frame + ((frameHeight - 1) - j)*frameWidth*4, frameWidth*4);
	}
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, textureWidth, textureHeight, 0, GL_BGRA, GL_UNSIGNED_BYTE, texturePixels);

	glColor4ub(255, 255, 255, 255);  // Must be put before glDisableClientState or error will occur
	glDisableClientState(GL_COLOR_ARRAY);
	glVertexPointer(2, GL_SHORT, 0, textureVertices);
	glEnableClientState(GL_VERTEX_ARRAY);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	
	// Do not apply the background texture to other things
	glDisable(GL_TEXTURE_2D);
	
	// Visualize
	if ([pose isValid]) {
		[pose apply];
		[visualizer visualize:iVisualizationMethod];
	} else {
		// TODO: notify that pose is invalid
	}
	
	// Refresh screen ----------------------------------------------------------
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	[context presentRenderbuffer:GL_RENDERBUFFER_OES];

	// Send Green channel to remote machines -----------------------------------
	if ([net isConnected]) {
		NSOutputStream *ostream = [net ostream];

		static BOOL sentInfo = FALSE;
		if (!sentInfo) {
			[ostream sendInt:frameWidth];
			[ostream sendInt:frameHeight];
			[ostream sendInt:0];  // Uncompressed
			sentInfo = TRUE;
		}
		
		uint8_t image[frameWidth*frameHeight];
		for (unsigned int j = 0; j < frameHeight; j++) {
			for (int i = 0; i < frameWidth; i++) {
				image[j*frameWidth + i] = frame[(j*frameWidth + i)*4 + 1];
			}
		}
		[ostream sendBytes:image length:frameWidth*frameHeight];
	}
}

//------------------------------------------------------------------------------

- (void)onReceive:(NSInputStream *)istream {
	static BOOL viewingFieldsReceived = FALSE;
	if (!viewingFieldsReceived) {
		[self onViewingFields:istream];
		viewingFieldsReceived = YES;
	} else {
		[self onPose:istream];
	}
}

- (void)onViewingFields:(NSInputStream *)istream {
	int segmentsPerEdge = [istream receiveInt];
	int numViewingFields = [istream receiveInt];
	
	viewingFields = [[NSMutableArray alloc] init];
	for (int i = 0; i < numViewingFields; i++) {
		ViewingField *viewingField = [[ViewingField alloc] initWithSegmentsPerEdge:segmentsPerEdge AndInputStream:istream];
		[viewingFields addObject:viewingField];
	}

	visualizer = [[Visualizer alloc] initWithViewingFields:viewingFields];
}

- (void)onPose:(NSInputStream *)istream {
	char *valid = [istream receiveBytes:1];
	if (*valid == 1) {
		float *numbers = (float *) [istream receiveBytes:28*sizeof(float)];
		[pose validate:numbers];
		free(numbers);
	} else {
		[pose invalidate];
	}
	free(valid);
}

//------------------------------------------------------------------------------

- (IBAction)changeVisualizationMethod:(id)sender {
	NSMutableArray *buttons = [[NSMutableArray alloc] init];
	[buttons addObject:self.m1];
	[buttons addObject:self.m2];
	[buttons addObject:self.m3];
	[buttons addObject:self.m4];
	[buttons addObject:self.m5];

	for (int i = 0; i < 5; i++) {
		id button = [buttons objectAtIndex:i];
		if (sender == button) {
			iVisualizationMethod = i;
			[button setBackgroundColor:[UIColor magentaColor]];
		} else {
			[button setBackgroundColor:[UIColor whiteColor]];
		}
	}

	[buttons release];
}

- (void)layoutSubviews {
	[EAGLContext setCurrentContext:context];
	[self destroyFramebuffer];
	[self createFramebuffer];
}

- (BOOL)createFramebuffer {
	glGenFramebuffersOES(1, &viewFramebuffer);
	glGenRenderbuffersOES(1, &viewRenderbuffer);
	
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	[context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(CAEAGLLayer*)self.layer];
	glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, viewRenderbuffer);
	
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
	
	if (USE_DEPTH_BUFFER) {
		glGenRenderbuffersOES(1, &depthRenderbuffer);
		glBindRenderbufferOES(GL_RENDERBUFFER_OES, depthRenderbuffer);
		glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, backingWidth, backingHeight);
		glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, depthRenderbuffer);
	}
	
	if(glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES) {
		NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
		return NO;
	}
	
	return YES;
}

- (void)destroyFramebuffer {	
	glDeleteFramebuffersOES(1, &viewFramebuffer);
	viewFramebuffer = 0;
	glDeleteRenderbuffersOES(1, &viewRenderbuffer);
	viewRenderbuffer = 0;
	
	if(depthRenderbuffer) {
		glDeleteRenderbuffersOES(1, &depthRenderbuffer);
		depthRenderbuffer = 0;
	}
}

- (void)dealloc {
	if ([EAGLContext currentContext] == context) {
		[EAGLContext setCurrentContext:nil];
	}
	[context release];
	context = nil;
	free(texturePixels);

	for (ViewingField *vf in viewingFields) {
		[vf release];
	}
	[viewingFields release];

	[visualizer release];

	[super dealloc];
}

@end
