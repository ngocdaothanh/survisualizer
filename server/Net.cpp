#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <netinet/in.h>
#include <unistd.h>


#include "Net.h"
#include "Config.h"

static Net *net_instance;

Net *Net::get_instance() {
	if (!net_instance) {
		net_instance = new Net();
	}
	return net_instance;
}

Net::Net() {
	m_socket = socket(AF_INET, SOCK_STREAM, 0);

	struct hostent *host;
	host = gethostbyname(HOST);
	struct sockaddr_in sin;
	memset(&sin, 0, sizeof sin);
	sin.sin_family = AF_INET;
	sin.sin_addr.s_addr = ((struct in_addr *)(host->h_addr))->s_addr;
	sin.sin_port = htons(PORT);
	if (connect(m_socket, (struct sockaddr *) &sin, sizeof(sin)) < 0) {
		printf("Error opening socket\n");
		exit(-1);
	}
}

Net::~Net()
{
	close(m_socket);
}

char *Net::recv_bytes(int size)
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

int Net::recv_int() {
	unsigned char *bytes = (unsigned char *) recv_bytes(4);
	int ret = bytes[0] + bytes[1]*256 + bytes[2]*256*256 + bytes[3]*256*256*256;
	delete[] bytes;
	return ret;
}

void Net::send_bytes(const char *bytes, int size) {
	int sent_bytes = 0;
	while (sent_bytes < size) {
		int ret = send(m_socket, bytes + sent_bytes, (size - sent_bytes), 0);
		if (ret < 0) {
			printf("Error sending data\n");
			exit(-1);
		}
		sent_bytes += ret;
	}
}

void Net::send_int(int value) {
	char *bytes = (char *) &value;
	send_bytes(bytes, 4);
}
