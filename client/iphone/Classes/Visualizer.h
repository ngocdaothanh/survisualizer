#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import "ViewingField.h"

@interface Visualizer : NSObject {
	ViewingField *viewingField;
}

- (id)initWithViewingField:(ViewingField *)viewingField;
- (void)visualize:(int)imethod;

@end
