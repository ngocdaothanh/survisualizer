#define WIN32_LEAN_AND_MEAN

#include <Windows.h>
#include <cvd/utility.h>
#include <zlib.h>

#include "VideoSource.h"
#include "Client.h"

using namespace CVD;
using namespace std;

// TODO: run the video receiving part in a thread

VideoSource::VideoSource()
{
	mirSize.x = Client::get_instance()->recv_int();
	mirSize.y = Client::get_instance()->recv_int();
};

/**
 * PTAM only needs grayscale to work. RGB is only needed for displaying. Thus we only need to
 * send grayscale images from the remote camera.
 *
 * Because Y = 0.3*Red + 0.59*Green + 0.11*Blue, to speedup more, the server send Green channel instead of Y!
 */
void VideoSource::GetAndFillFrameBWandRGB(Image<CVD::byte> &imBW, Image<CVD::Rgb<CVD::byte> > &imRGB)
{
#ifdef USE_ZLIB
	unsigned char *image = new unsigned char[mirSize.x*mirSize.y];

	// Get size in header
	int size = recv_int();

	// Get image
	char *compressed_image = recv_bytes(size);
	uLongf image_size;
	uncompress((Bytef *) m_buffer, &image_size, (Bytef *) compressed_image, size);
	delete[] compressed_image;
#else
	unsigned char *image = (unsigned char *) Client::get_instance()->recv_bytes(mirSize.x*mirSize.y);
#endif
	// The code below can be optimized by copy the whole m_buffer to the neccessary destination
	for (int y = 0; y < mirSize.y; y++) {
		for (int x = 0; x < mirSize.x; x++) {
			CVD::byte value = image[y*mirSize.x + x];
			imRGB[y][x].red   = value;
			imRGB[y][x].green = value;
			imRGB[y][x].blue  = value;

			imBW[y][x] = value;
		}
	}
	delete[] image;
}

ImageRef VideoSource::Size()
{
	return mirSize;
}
