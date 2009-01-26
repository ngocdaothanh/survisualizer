#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import "ViewingField.h"

@interface Visualizer : NSObject {
	NSMutableArray *viewingFields;
}

- (id)initWithViewingFields:(NSMutableArray *)viewingFields;
- (void)visualize:(int)imethod;

@end
