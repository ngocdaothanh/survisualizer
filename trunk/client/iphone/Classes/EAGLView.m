#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>

//------------------------------------------------------------------------------

#import "EAGLView.h"
#import "Surface.h"
#import "SurfaceAccelerator.h"

#define USE_DEPTH_BUFFER 0

@interface EAGLView()
@property (nonatomic, retain) EAGLContext *context;

- (BOOL)createFramebuffer;
- (void)destroyFramebuffer;
@end

//------------------------------------------------------------------------------

static FUNC_camera_callback original_camera_callback = NULL;
static EAGLView *glView = NULL;

static int __camera_callbackHook(CameraDeviceRef cameraDevice, int a, CoreSurfaceBufferRef coreSurfaceBuffer, int b) {
	if (coreSurfaceBuffer) {
		Surface *surface = [[Surface alloc]initWithCoreSurfaceBuffer:coreSurfaceBuffer];
		[surface lock];
		[glView drawView:surface.baseAddress withWidth:surface.width withHeight:surface.height];
		[surface unlock];
		[surface release];
	}
	return (*original_camera_callback)(cameraDevice, a, coreSurfaceBuffer, b);
}

//------------------------------------------------------------------------------

@implementation EAGLView

@synthesize context;

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

- (Pose *)getPose {
	return pose;
}

/**
 * Called by SurvisualizerAppDelegate's applicationDidFinishLaunching because
 * PLCameraController is only available after UIImagePickerController has been
 * loaded.
 */
- (void)installCameraCallbackHook {
	glView = self;

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

- (void)drawView:(uint8_t *)pixels withWidth:(int)width withHeight:(int)height {
	static BOOL initialized = NO;
	static int zoomedWidth;
	static int zoomedHeight;
	static GLfloat backgroundVertices[8];
	static GLfloat backgroundTexcoords[8];
	
	// Things that only need to set once is set here
	// They are here because we need width and height, which do not change over time
	if (!initialized) {
		// Texture dimensions must be a power of 2. If you write an application that allows users to supply an image,
		// you'll want to add code that checks the dimensions and takes appropriate action if they are not a power of 2.
		backgroundTextureWidth  = 512;
		backgroundTextureHeight = 512;
		backgroundPixels = malloc(backgroundTextureWidth*backgroundTextureHeight*4);
		glGenTextures(1, &backgroundTexture);
		glBindTexture(GL_TEXTURE_2D, backgroundTexture);
		
		zoomedWidth = backingWidth;
		zoomedHeight = (float) height*backingWidth/width;

		backgroundVertices[0] = 0;            backgroundVertices[1] = 0;
		backgroundVertices[2] = zoomedWidth;  backgroundVertices[3] = 0;
		backgroundVertices[4] = 0;            backgroundVertices[5] = zoomedHeight;
		backgroundVertices[6] = zoomedWidth;  backgroundVertices[7] = zoomedHeight;
		
		backgroundTexcoords[0] = 0;                                       backgroundTexcoords[1] = 0;
		backgroundTexcoords[2] = (GLfloat) width/backgroundTextureWidth;  backgroundTexcoords[3] = 0;
		backgroundTexcoords[4] = 0;                                       backgroundTexcoords[5] = (GLfloat) height/backgroundTextureHeight;
		backgroundTexcoords[6] = (GLfloat) width/backgroundTextureWidth;  backgroundTexcoords[7] = (GLfloat) height/backgroundTextureHeight;
		
		glViewport(0, 0, zoomedWidth, zoomedHeight);
		
		initialized = YES;
	}

	[EAGLContext setCurrentContext:context];
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
	
	// Draw background ---------------------------------------------------------
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glOrthof(0, zoomedWidth, 0, zoomedHeight, -1, 1);
	
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);  // Set the texture parameters to use a minifying filter and a linear filer (weighted average)
	glEnable(GL_TEXTURE_2D);										   // Enable use of the texture
	glDisable(GL_BLEND);                                               // Background doesn't need blending
	glTexCoordPointer(2, GL_FLOAT, 0, backgroundTexcoords);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	for (int j = 0; j < height; j++) {
		memcpy(backgroundPixels + j*backgroundTextureWidth*4, pixels + ((height - 1) - j)*width*4, width*4);
	}
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, backgroundTextureWidth, backgroundTextureHeight, 0, GL_BGRA, GL_UNSIGNED_BYTE, backgroundPixels);
	
	glDisableClientState(GL_COLOR_ARRAY);
	glVertexPointer(2, GL_FLOAT, 0, backgroundVertices);
	glEnableClientState(GL_VERTEX_ARRAY);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	
	// Do not apply the background texture to other things
	glDisable(GL_TEXTURE_2D);
	//glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);						 // Set a blending function to use
	//glEnable(GL_BLEND);												 // Enable blending
	
	// Visualize
	if ([pose isValid]) {
		[pose apply];
		[self visualize];
	}
	
	// Refresh screen ----------------------------------------------------------
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	[context presentRenderbuffer:GL_RENDERBUFFER_OES];
	
	// Send Green channel to remote machines -----------------------------------
	if ([net connected]) {
		static BOOL sentInfo = FALSE;
		if (!sentInfo) {
			[net sendInt:width];
			[net sendInt:height];
			[net sendInt:0];  // Uncompressed
			sentInfo = TRUE;
		}

		uint8_t image[width*height];
		for (unsigned int j = 0; j < height; j++) {
			for (int i = 0; i < width; i++) {
				image[j*width + i] = pixels[(j*width + i)*4 + 1];
			}
		}
		[net sendBytes:image length:width*height];
	}
}

- (void)onPose:(NSInputStream *)istream {
	uint8_t *valid = [net readBytes:istream length:1];
	if (*valid == 1) {
		float *numbers = (float *) [net readBytes:istream length:28*sizeof(float)];
		[pose validate:numbers];
		free(numbers);
	} else {
		[pose invalidate];
	}
	free(valid);
}

- (void)visualize {
	const GLfloat squareVertices[] = {
        -0.5f, -0.5f,
        0.5f,  -0.5f,
        -0.5f,  0.5f,
        0.5f,   0.5f,
    };
    const GLubyte squareColors[] = {
        255, 255,   0, 255,
        0,   255, 255, 255,
        0,     0,   0,   0,
        255,   0, 255, 255,
    };

    glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
    
    //glClearColor(0.5f, 0.5f, 0.5f, 1.0f);
    //glClear(GL_COLOR_BUFFER_BIT);

    glVertexPointer(2, GL_FLOAT, 0, squareVertices);
    glEnableClientState(GL_VERTEX_ARRAY);
    glColorPointer(4, GL_UNSIGNED_BYTE, 0, squareColors);
    glEnableClientState(GL_COLOR_ARRAY);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
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
	free(backgroundPixels);
	[super dealloc];
}

@end
