#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

#import "Net.h"
#import "Pose.h"
#import "Visualizer.h"

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

	NSMutableArray *viewingFields;

	int iVisualizationMethod;
	Visualizer *visualizer;
}

- (void)installCameraCallbackHook;
- (void)drawView;
- (void)onReceive:(NSInputStream *)istream;

@property (nonatomic, retain) IBOutlet UIButton *m1;
@property (nonatomic, retain) IBOutlet UIButton *m2;
@property (nonatomic, retain) IBOutlet UIButton *m3;
@property (nonatomic, retain) IBOutlet UIButton *m4;
@property (nonatomic, retain) IBOutlet UIButton *m5;
- (IBAction)changeVisualizationMethod:(id)sender;
@end
