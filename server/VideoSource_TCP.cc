#include <cvd/utility.h>
#include <zlib.h>

#include "VideoSource.h"
#include "Net.h"

using namespace CVD;
using namespace std;

// TODO: run the video receiving part in a thread

VideoSource::VideoSource()
{
	mirSize.x = Net::get_instance()->recv_int();
	mirSize.y = Net::get_instance()->recv_int();
	compress  = Net::get_instance()->recv_int();
};

/**
 * PTAM only needs grayscale to work. RGB is only needed for displaying. Thus we only need to
 * send grayscale images from the remote camera.
 *
 * Because Y = 0.3*Red + 0.59*Green + 0.11*Blue, to speedup more, the server send Green channel instead of Y!
 */
void VideoSource::GetAndFillFrameBW(Image<CVD::byte> &imBW)
{
	unsigned char *image;
	uLongf image_size = mirSize.area();
	if (compress) {
		image = new unsigned char[image_size];

		// Get size in header
		int compressed_size = Net::get_instance()->recv_int();

		// Get image
		char *compressed_image = Net::get_instance()->recv_bytes(compressed_size);
		uncompress((Bytef *) image, &image_size, (const Bytef *) compressed_image, compressed_size);
		delete[] compressed_image;
	} else {
		image = (unsigned char *) Net::get_instance()->recv_bytes(image_size);
	}
	BasicImage<byte> bi(image, mirSize);
	imBW.copy_from(bi);
	delete[] image;
}

ImageRef VideoSource::Size()
{
	return mirSize;
}
