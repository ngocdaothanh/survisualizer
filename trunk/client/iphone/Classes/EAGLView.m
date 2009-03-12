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

- (void)receiveModel:(NSInputStream *)istream;
- (void)receiveViewingFields:(NSInputStream *)istream;
- (void)receivePose:(NSInputStream *)istream;

- (void)drawMapMode;
- (void)drawRealMode;

#ifdef SHOOT_SCREEN
- (void)shootScreen;
#endif
@end

//------------------------------------------------------------------------------

static FUNC_camera_callback original_camera_callback = NULL;

static uint8_t *frameBGRA = NULL;
static uint8_t *frameG    = NULL;  // Using NSLock on frameG seriously decreases frame rate sending to remote machines
static int frameWidth  = 0;
static int frameHeight = 0;

static int __camera_callbackHook(CameraDeviceRef cameraDevice, int a, CoreSurfaceBufferRef coreSurfaceBuffer, int b) {
	if (coreSurfaceBuffer) {
		Surface *surface = [[Surface alloc]initWithCoreSurfaceBuffer:coreSurfaceBuffer];
		[surface lock];

		if (!frameBGRA) {
			frameWidth  = surface.width;
			frameHeight = surface.height;

			frameBGRA = malloc(frameWidth*frameHeight*4);
			frameG    = malloc(frameWidth*frameHeight);
		}
#ifndef LAST_STORED_FRAME
#ifndef ROTATE
		memcpy(frameBGRA, surface.baseAddress, frameWidth*frameHeight*4);
		for (int j = 0; j < frameHeight; j++) {
			for (int i = 0; i < frameWidth; i++) {
				frameG[j*frameWidth + i] = frameBGRA[(j*frameWidth + i)*4 + 1];
			}
		}
#else
		// FIXME: rotate
		memcpy(frameBGRA, surface.baseAddress, frameWidth*frameHeight*4);

		for (int j = 0; j < frameHeight; j++) {
			for (int i = 0; i < frameWidth; i++) {
				frameG[i*frameHeight + (frameHeight - (j + 1))] = frameBGRA[(j*frameWidth + i)*4 + 1];
			}
		}
#endif
#endif
		[surface unlock];
		[surface release];
	}
	return (*original_camera_callback)(cameraDevice, a, coreSurfaceBuffer, b);
}

//------------------------------------------------------------------------------

@implementation EAGLView

@synthesize bMethod1;
@synthesize bMethod2;
@synthesize bMethod3;
@synthesize bMethod4;
@synthesize bMethod5;
@synthesize bMapMode;

+ (Class)layerClass {
	return [CAEAGLLayer class];
}

- (id)initWithCoder:(NSCoder*)coder {
	if (self = [super initWithCoder:coder]) {
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
		NSError *startError = nil;
		[net setType:@"_survisualizer._tcp."];
		if (![net start:&startError] ) {
			NSLog(@"Error starting server: %@", startError);
		} else {
			NSLog(@"Started server on port %d", [net port]);
		}
	}
	return self;
}

- (void)installCameraCallbackHook {
	id cameraController = [objc_getClass("PLCameraController") sharedInstance];
	[cameraController startPreview];
	[Surface dynamicLoad];

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

	[NSThread detachNewThreadSelector:@selector(sendFrameLoop:) toTarget:self withObject:nil];
	[NSThread detachNewThreadSelector:@selector(drawOpenGLLoop:) toTarget:self withObject:nil];
}

#ifdef LAST_STORED_FRAME
- (void)loadFromFile {
	// A in BGRA is unused
	
	static int storedVideo = 0;
	static BOOL increasingDirection = YES;
	
	NSString *fileName = [[NSString alloc] initWithFormat:@"/private/var/mobile/Surveillance/in/%03d.raw", storedVideo];
	NSData *data = [NSData dataWithContentsOfFile:fileName];
	
	uint8_t *bytes = (uint8_t *) [data bytes];
	
#ifndef ROTATE
	for (unsigned int i = 0; i < frameWidth; i++) {
		uint8_t byte = bytes[i];
		frameBGRA[i*4 + 0] = byte;
		frameBGRA[i*4 + 1] = byte;
		frameBGRA[i*4 + 2] = byte;
	}
#else
	for (unsigned int j = 0; j < frameHeight; j++) {
		for (unsigned int i = 0; i < frameWidth; i++) {
			uint8_t byte = bytes[i*frameHeight + (frameHeight - (j + 1))];
			frameBGRA[(j*frameWidth + i)*4 + 0] = byte;
			frameBGRA[(j*frameWidth + i)*4 + 1] = byte;
			frameBGRA[(j*frameWidth + i)*4 + 2] = byte;
		}
	}
#endif
	//memcpy(frameBGRA, [data bytes], [data length]);

	//[data autorelease];
	[fileName release];
	
	// Reset storedVideo if the pose is invalid (note that pose is invalid when the map has not been created on the PTAM side)
	if ([pose isValid]) {
		if (increasingDirection) {
			storedVideo++;
			if (storedVideo > LAST_STORED_FRAME) {
				storedVideo = LAST_STORED_FRAME;
				increasingDirection = NO;
			}
		} else {
			storedVideo--;
			if (storedVideo < 0) {
				storedVideo = 0;
				increasingDirection = YES;
			}
		}
	} else {
		storedVideo = 0;
	}	
}
#endif

// Send the image to remote machines.
- (void)sendFrameLoop:(id)object {
	while (TRUE) {
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc]init];

#ifdef LAST_STORED_FRAME
		[self loadFromFile];		
#endif
		
		if ([net isConnected]) {
			NSOutputStream *ostream = [net ostream];
			
			static BOOL headerSent = FALSE;
			if (!headerSent) {
#ifndef ROTATE
				[ostream sendInt:frameWidth];
				[ostream sendInt:frameHeight];
#else
				[ostream sendInt:frameHeight];
				[ostream sendInt:frameWidth];
#endif
#ifdef SEND_G
				[ostream sendInt:GL_LUMINANCE];
#else
				[ostream sendInt:GL_BGRA];
#endif
				[ostream sendInt:0];  // Uncompressed
				headerSent = TRUE;
			}
#ifdef SEND_G	
			for (unsigned int j = 0; j < frameHeight; j++) {
				for (unsigned int i = 0; i < frameWidth; i++) {
					frameG[i*frameHeight + (frameHeight - (j + 1))] = frameBGRA[(j*frameWidth + i)*4 + 1];
				}
			}
			 
			[ostream sendBytes:frameG length:frameWidth*frameHeight];
#else
			[ostream sendBytes:frameBGRA length:frameWidth*frameHeight*4];
#endif
		}

		[pool release];
	}
	[NSThread exit];
}

- (void)drawOpenGLLoop:(id)object {
	while (TRUE) {
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc]init];

		// The background texture is scaled to fit the OpenGL surface (backingWidth x backingHeight)
		if (!textureInitialized && backingWidth != 0 && backingHeight != 0 && frameWidth != 0 && frameHeight != 0) {
			glGenTextures(1, &texture);
			glBindTexture(GL_TEXTURE_2D, texture);

			textureWidth  = 512;
			textureHeight = 512;
			texturePixels = malloc(textureWidth*textureHeight*4);

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

		if (frameBGRA) {
			[EAGLContext setCurrentContext:context];
			glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
			glViewport(0, 0, backingWidth, backingHeight);  // Viewport must be called everytime, don't know why
			glClearColor(255, 255, 255, 255);
			glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
			if (mapMode) {
				[self drawMapMode];
			} else {
				[self drawRealMode];
			}

#ifdef SHOOT_SCREEN
			[self shootScreen];
#endif
			
			glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
			[context presentRenderbuffer:GL_RENDERBUFFER_OES];			
		}

		[pool release];
	}
	[NSThread exit];
}

- (void)drawRealMode {
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glOrthof(0, backingWidth, 0, backingHeight, -1, 1);
	
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glEnable(GL_TEXTURE_2D);
	glDisable(GL_BLEND);  // Background doesn't need blending
	
	glTexCoordPointer(2, GL_FLOAT, 0, textureCoords);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	for (int j = 0; j < frameHeight; j++) {
		memcpy(texturePixels + j*textureWidth*4, frameBGRA + ((frameHeight - 1) - j)*frameWidth*4, frameWidth*4);
	}
	// The internal format must be GL_RGBA
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, textureWidth, textureHeight, 0, GL_BGRA, GL_UNSIGNED_BYTE, texturePixels);

	glColor4ub(255, 255, 255, 255);  // Must be put before glDisableClientState or error will occur
	glDisableClientState(GL_COLOR_ARRAY);
	glVertexPointer(2, GL_SHORT, 0, textureVertices);
	glEnableClientState(GL_VERTEX_ARRAY);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	
	// Do not apply the background texture to other things
	glDisable(GL_TEXTURE_2D);

	if ([pose isValid] && visualizer) {
		glDisable(GL_CLIP_PLANE0);
		glDisable(GL_CLIP_PLANE1);
		glDisable(GL_CLIP_PLANE2);
		glDisable(GL_CLIP_PLANE3);
		glDisable(GL_CLIP_PLANE4);
		glDisable(GL_CLIP_PLANE5);
		
		glMatrixMode(GL_PROJECTION);  
		glLoadIdentity();
#ifdef ROTATE
		glRotatef(90, 0, 0, 1);
#endif
		[pose apply];

		glMatrixMode(GL_MODELVIEW);
		glLoadIdentity();

		// Draw 0xyz to debug
		float a[6] = {
			0, 0, 0,
			1, 0, 0
		};
		glEnableClientState(GL_VERTEX_ARRAY);
		glVertexPointer(3, GL_FLOAT, 0, a);
		glColor4ub(255, 0, 0, 255);
		glDrawArrays(GL_LINES, 0, 2);
		
		a[3] = 0; a[4] = 1;
		glVertexPointer(3, GL_FLOAT, 0, a);
		glColor4ub(0, 255, 0, 255);
		glDrawArrays(GL_LINES, 0, 2);
		
		a[4] = 0; a[5] = 1;
		glVertexPointer(3, GL_FLOAT, 0, a);
		glColor4ub(0, 0, 255, 255);
		glDrawArrays(GL_LINES, 0, 2);


		// Draw model
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		glEnable(GL_BLEND);
		glColor4ub(0, 255, 255, 32);
		glVertexPointer(3, GL_FLOAT, 0, triangles);
		glEnableClientState(GL_VERTEX_ARRAY);
		glDrawArrays(GL_TRIANGLES, 0, 3*numTriangles);
		
		[visualizer visualize:iVisualizationMethod];
	}
}

- (void)drawMapMode {
	if (!triangles) {
		return;
	}
	
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glOrthof(0, mapY, 0, mapY*backingHeight/backingWidth, -1000, 1000);
	
	// Look from the sky to the ground
	glRotatef(90, 1, 0, 0);
	glTranslatef(mapX, 0, mapZ);
	
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	
	glTranslatef(pose.dP.x, pose.dP.y, pose.dP.z);
	
#ifdef ROTATE
	glRotatef(90, 0, 1, 0);
#endif
	
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glEnable(GL_BLEND);
	glColor4ub(0, 0, 0, 15);
	
	glVertexPointer(3, GL_FLOAT, 0, triangles);
	glEnableClientState(GL_VERTEX_ARRAY);
	glDrawArrays(GL_TRIANGLES, 0, 3*numTriangles);
	
	if (visualizer) {
		[visualizer visualize:iVisualizationMethod];
	}
	
	// Draw current position
	if ([pose isValid]) {
		// Adjust camera position
		Point3D translation = pose.translation;
		NSLog(@"%f", translation.z);
		Point3D position = pose.dP;
		translation.x += position.x;
		translation.y += position.y;
		translation.z += position.z;
		
		glPointSize(7);
		glColor4ub(0, 255, 0, 127);
		glVertexPointer(3, GL_FLOAT, 0, &translation);
		glDrawArrays(GL_POINTS, 0, 1);
	}
}

#ifdef SHOOT_SCREEN
/**
 * glReadPixels(0, 0, backingWidth, backingHeight, GL_RGB, GL_UNSIGNED_BYTE, bytes)
 * gives black screenshot, thus we need to
 * glReadPixels(0, 0, backingWidth, backingHeight, GL_RGBA, GL_UNSIGNED_BYTE, bytes)
 */
- (void)shootScreen {
	static int iFrame = 0;
	NSString *fileName = [NSString stringWithFormat:@"%@/Documents/%03d.%d.%d.%d.raw", NSHomeDirectory(), iFrame, backingWidth, backingHeight, GL_BGRA];
	iFrame++;
	NSLog(fileName);

	int length = 4*backingWidth*backingHeight;
	char *bytes = malloc(length);
	glReadPixels(0, 0, backingWidth, backingHeight, GL_BGRA, GL_UNSIGNED_BYTE, bytes);  // Must be GL_BGRA

	NSData *data = [NSData dataWithBytes:bytes length:length];
	[data writeToFile:fileName atomically:NO];

	//[data autorelease];
	//[fileName release];
	free(bytes);
}
#endif

//------------------------------------------------------------------------------

- (void)onReceive:(NSInputStream *)istream {
	static BOOL modelAndViewingFieldsReceived = NO;

	if (modelAndViewingFieldsReceived) {
		[self receivePose:istream];
	} else {
		[self receiveModel:istream];
		[self receiveViewingFields:istream];
		modelAndViewingFieldsReceived = YES;
	}
}

- (void)receiveModel:(NSInputStream *)istream {
	numTriangles = [istream receiveInt];
	triangles = (Point3D *) [istream receiveBytes:numTriangles*3*sizeof(Point3D)];
	
	// TODO: calculate
	mapX = 60;
	mapY = backingWidth/3;
	mapZ = -120;
}

- (void)receiveViewingFields:(NSInputStream *)istream {
	int segmentsPerEdge = [istream receiveInt];
	int numViewingFields = [istream receiveInt];
	
	viewingFields = [[NSMutableArray alloc] init];
	for (int i = 0; i < numViewingFields; i++) {
		ViewingField *viewingField = [[ViewingField alloc] initWithSegmentsPerEdge:segmentsPerEdge AndInputStream:istream];
		[viewingFields addObject:viewingField];
	}

	visualizer = [[Visualizer alloc] initWithViewingFields:viewingFields];
}

- (void)receivePose:(NSInputStream *)istream {
	char *valid = [istream receiveBytes:1];
	if (*valid == 1) {
		float *numbers = (float *) [istream receiveBytes:(28 + 3 + 3)*sizeof(float)];
		[pose validate:numbers];
		free(numbers);
	} else {
		[pose invalidate];
	}
	free(valid);
}

//------------------------------------------------------------------------------

- (IBAction)toggleMapMethod:(id)sender {
	mapMode = !mapMode;

	if (mapMode) {
		[self.bMapMode setBackgroundColor:[UIColor magentaColor]];
	} else {
		[self.bMapMode setBackgroundColor:[UIColor whiteColor]];
	}
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	if (!mapMode) {
		return;
	}

	mapLastPoint = [[touches anyObject] locationInView:self];
	mapLastDistance = -1;  // Mark that this distance is invalid
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event {
	if (!mapMode) {
		return;
	}

	NSSet *allTouches = [event allTouches];	
	int count = [allTouches count];
	if (count == 1) {         // Move
		UITouch *touch = [[allTouches allObjects] objectAtIndex:0];
		CGPoint p = [touch locationInView:self];
		mapX += (p.x - mapLastPoint.x)*mapY/backingWidth;
		mapZ += (p.y - mapLastPoint.y)*mapY/backingWidth;
		mapLastPoint = p;
	} else if (count == 2) {  // Zoom
		UITouch *touch1 = [[allTouches allObjects] objectAtIndex:0];
		UITouch *touch2 = [[allTouches allObjects] objectAtIndex:1];
		
		CGPoint p1 = [touch1 locationInView:self];
		CGPoint p2 = [touch2 locationInView:self];

		float dx = p1.x - p2.x;
		float dy = p1.y - p2.y;
		float d = sqrt(dx*dx + dy*dy);
		if (mapLastDistance > 0) {
			mapY -= d - mapLastDistance;
			if (mapY < 2) {  // Too low
				mapY = 2;
			}
		}
		mapLastDistance = d;
	}
}

//------------------------------------------------------------------------------

- (IBAction)changeVisualizationMethod:(id)sender {
	NSMutableArray *buttons = [[NSMutableArray alloc] init];
	[buttons addObject:self.bMethod1];
	[buttons addObject:self.bMethod2];
	[buttons addObject:self.bMethod3];
	[buttons addObject:self.bMethod4];
	[buttons addObject:self.bMethod5];

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

//------------------------------------------------------------------------------

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

	free(texturePixels);
	free(triangles);

	for (ViewingField *vf in viewingFields) {
		[vf release];
	}
	[viewingFields release];

	[visualizer release];
	[super dealloc];
}

@end
