#include <stdio.h>

#include "Client.h"
#include "Config.h"

static Client *client_instance;

Client *Client::get_instance() {
	if (!client_instance) {
		client_instance = new Client();
	}
	return client_instance;
}

Client::Client() {
	WSADATA wsaData;
	WORD version;
	int error;
	version = MAKEWORD( 2, 0 );
	error = WSAStartup( version, &wsaData );
	if (error != 0) {
		exit(-1);
	}
	
	if (LOBYTE(wsaData.wVersion) != 2 || HIBYTE(wsaData.wVersion) != 0) {
		WSACleanup();
		exit(-1);
	}

	m_socket = socket(AF_INET, SOCK_STREAM, 0);

	struct hostent *host;
	host = gethostbyname(HOST);
	struct sockaddr_in sin;
	memset(&sin, 0, sizeof sin);
	sin.sin_family = AF_INET;
	sin.sin_addr.s_addr = ((struct in_addr *)(host->h_addr))->s_addr;
	sin.sin_port = htons(PORT);
	if (connect(m_socket, (struct sockaddr *) &sin, sizeof(sin)) == SOCKET_ERROR) {
		printf("Error opening socket\n");
		exit(-1);
	}
}

Client::~Client()
{
	closesocket(m_socket);
	WSACleanup();
}

char *Client::recv_bytes(int size)
{
	int total = 0;
	char *ret = new char[size];
	while (total < size) {
		char *buffer = new char[size - total];
		int recv_size = recv(m_socket, buffer, size - total, 0);
		if (recv_size <= 0) {
			printf("Error receiving data\n");
			exit(-1);
		}
		memcpy(ret + total, buffer, recv_size);
		delete[] buffer;
		total += recv_size;
	}

	return ret;
}

int Client::recv_int() {
	unsigned char *bytes = (unsigned char *) recv_bytes(4);
	int ret = bytes[0] + bytes[1]*256 + bytes[2]*256*256 + bytes[3]*256*256*256;
	delete[] bytes;
	return ret;
}
