#ifndef __CLIENT__
#define __CLIENT__

class Client {
public:
	static Client *get_instance();

	char *recv_bytes(int size);
	int recv_int();

	void send_bytes(const char *bytes, int size);
	void send_int(int value);

private:
	Client();
	~Client();

private:
	int m_socket;
};

#endif