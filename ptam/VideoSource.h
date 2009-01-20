#include <cvd/image.h>
#include <cvd/byte.h>
#include <cvd/rgb.h>

struct VideoSourceData;

class VideoSource
{
public:
	VideoSource();
	void GetAndFillFrameBWandRGB(CVD::Image<CVD::byte> &imBW);
	CVD::ImageRef Size();

private:
	CVD::ImageRef mirSize;
	bool compress;
};
