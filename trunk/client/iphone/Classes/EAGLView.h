#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

#import "Net.h"
#import "Pose.h"
#import "Visualizer.h"
#import "CameraAdjustorView.h"

/**
 * This class wraps the CAEAGLLayer from CoreAnimation into a convenient UIView subclass.
 * The view content is basically an EAGL surface you render your OpenGL scene into.
 * Note that setting the view non-opaque will only work if the EAGL surface has an alpha channel.
 */
@interface EAGLView : UIView {	  
@private
	BOOL textureInitialized;

	// The pixel dimensions of the backbuffer
	GLint backingWidth;
	GLint backingHeight;

	EAGLContext *context;
	GLuint viewRenderbuffer, viewFramebuffer;
	GLuint depthRenderbuffer;

	GLuint texture;
	int textureWidth, textureHeight;
	GLshort textureVertices[8];
	GLfloat textureCoords[8];
	uint8_t *texturePixels;

	Net *net;
	Pose *pose;

	// Model
	int numTriangles;
	Point3D *triangles;

	NSMutableArray *viewingFields;

	BOOL    mapMode;
	float   mapX, mapY, mapZ;
	CGPoint mapLastPoint;   // Drag
	float   mapLastDistance;  // Zoom
	
	int iVisualizationMethod;
	Visualizer *visualizer;

    CameraAdjustorView *caView;
}

- (void)installCameraCallbackHook;
- (void)onReceive:(NSInputStream *)istream;

@property (nonatomic, retain) CameraAdjustorView *caView;

@property (nonatomic, retain) IBOutlet UIButton *bMethod1;
@property (nonatomic, retain) IBOutlet UIButton *bMethod2;
@property (nonatomic, retain) IBOutlet UIButton *bMethod3;
@property (nonatomic, retain) IBOutlet UIButton *bMethod4;
@property (nonatomic, retain) IBOutlet UIButton *bMethod5;
@property (nonatomic, retain) IBOutlet UIButton *bMapMode;

- (IBAction)toggleMapMethod:(id)sender;
- (IBAction)changeVisualizationMethod:(id)sender;

@end
