#import "ViewingField.h"
#import "Net.h"

@implementation ViewingField

- (id)initWithSegmentPerEdge:(int)spe AndInputStream:(NSInputStream *)istream {
	if (self = [super init]) {
		segmentsPerEdge = spe;
		int numHeads = (segmentsPerEdge + 1)*(segmentsPerEdge + 1);
		
		char *bytes;
		int length;

		length = 3*sizeof(float);
		bytes = [istream receiveBytes:length];
		memcpy(position, bytes, length);
		free(bytes);

		length = numHeads*sizeof(3*sizeof(float));
		bytes = [istream receiveBytes:length];
		headsOnCamera = (Point3D *) malloc(sizeof(Point3D));
		memcpy(headsOnCamera, bytes, length);
		free(bytes);

		length = numHeads*sizeof(3*sizeof(float));
		bytes = [istream receiveBytes:length];
		headsOnTriangles = (Point3D *) malloc(sizeof(Point3D));
		memcpy(headsOnTriangles, bytes, length);
		free(bytes);
	}
	return self;
}

- (void)dealloc {
	free(headsOnCamera);
	free(headsOnTriangles);
	[super dealloc];
}

@end
