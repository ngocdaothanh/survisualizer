#include <cvd/image.h>
#include <cvd/byte.h>
#include <cvd/thread.h>

struct VideoSourceData;

/**
 * PTAM only needs grayscale to work. RGB is only needed for displaying. Thus we only need to
 * send grayscale images from the remote camera.
 *
 * Because Y = 0.3*Red + 0.59*Green + 0.11*Blue, to speedup more, the server send Green channel instead of Y!
 */
class VideoSource: protected CVD::Thread
{
public:
	VideoSource();
	~VideoSource();
	void GetAndFillFrameBW(CVD::Image<CVD::byte> &imBW);
	CVD::ImageRef Size();

protected:
	virtual void run();

private:
	CVD::ImageRef mirSize;
	bool mcompress;
	unsigned char *mimage;
};
