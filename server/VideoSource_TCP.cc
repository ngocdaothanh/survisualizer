#include <cvd/utility.h>
#include <zlib.h>

#include "VideoSource.h"
#include "Net.h"

using namespace CVD;
using namespace std;

VideoSource::VideoSource()
{
	mirSize.x = Net::get_instance()->recv_int();
	mirSize.y = Net::get_instance()->recv_int();
	mcompress = Net::get_instance()->recv_int();

	mimage = new unsigned char[mirSize.area()];
	start();
};

VideoSource::~VideoSource()
{
	stop();
	while (isRunning());  // Wait until the thread stops
	delete[] mimage;
}

void VideoSource::GetAndFillFrameBW(Image<CVD::byte> &imBW)
{
	BasicImage<byte> bi(mimage, mirSize);
	imBW.copy_from(bi);
}

ImageRef VideoSource::Size()
{
	return mirSize;
}

void VideoSource::run()
{
	while (!shouldStop()) {
		unsigned char *image;
		uLongf image_size = mirSize.area();
		if (mcompress) {
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
		memcpy(mimage, image, image_size);
		delete[] image;
	}
}
