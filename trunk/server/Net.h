#ifndef __NET__
#define __NET__

class Net {
public:
	static Net *get_instance();

	char *recv_bytes(int size);
	int recv_int();

	void send_bytes(const char *bytes, int size);
	void send_int(int value);

private:
	Net();
	~Net();

private:
	int m_socket;
};

#endif
