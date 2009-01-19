#ifndef __CLIENT__
#define __CLIENT__

#include <winsock2.h>
//#include <winsock.h>

class Client {
public:
	static Client *get_instance();

	char *recv_bytes(int size);
	int recv_int();

private:
	Client();
	~Client();

private:
	SOCKET m_socket;
};

#endif
