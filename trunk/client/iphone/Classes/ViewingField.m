#import "ViewingField.h"
#import "Net.h"

@implementation ViewingField

@synthesize position;
@synthesize segmentsPerEdge;
@synthesize headsOnCamera;
@synthesize headsOnTriangles;

- (id)initWithSegmentsPerEdge:(int)spe AndInputStream:(NSInputStream *)istream {
	if (self = [super init]) {
		segmentsPerEdge = spe;
		int numHeads = (segmentsPerEdge + 1)*(segmentsPerEdge + 1);

		char *bytes;
		int length;

		length = 3*sizeof(float);
		bytes = [istream receiveBytes:length];
		memcpy(&position, bytes, length);
		free(bytes);

		length = numHeads*3*sizeof(float);
		bytes = [istream receiveBytes:length];
		headsOnCamera = (Point3D *) malloc(length);
		memcpy(headsOnCamera, bytes, length);
		free(bytes);

		length = numHeads*3*sizeof(float);
		bytes = [istream receiveBytes:length];
		headsOnTriangles = (Point3D *) malloc(length);
		memcpy(headsOnTriangles, bytes, length);
		free(bytes);

		/*
		float s = 0.05;
		position.x *= s;
		position.y *= s;
		position.z *= s;
		for (int i = 0; i < numHeads; i++) {
			headsOnCamera[i].x *= s;
			headsOnCamera[i].y *= s;
			headsOnCamera[i].z *= s;
			
			headsOnTriangles[i].x *= s;
			headsOnTriangles[i].y *= s;
			headsOnTriangles[i].z *= s;
		}*/
	}
	return self;
}

- (void)dealloc {
	free(headsOnCamera);
	free(headsOnTriangles);
	[super dealloc];
}

@end
