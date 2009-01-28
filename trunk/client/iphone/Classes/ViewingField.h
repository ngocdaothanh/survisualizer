#import "Point3D.h"

@interface ViewingField : NSObject {
	Point3D position;
	int segmentsPerEdge;
	Point3D *heads;
}

- (id)initWithSegmentsPerEdge:(int)segmentsPerEdge AndInputStream:(NSInputStream *)istream;

@property (readonly) Point3D position;
@property (readonly) int segmentsPerEdge;
@property (readonly) Point3D *heads;

@end
