#include <arpa/inet.h>
#include <cstdlib>
#include <cstring>
#include <iostream>
#include <string>
#include <sys/socket.h>
#include <unistd.h>
#include <sys/types.h>
#include <netdb.h>

/*
Exit codes:
0 - pharosd ok
1 - pharosd no
2 - usage error
3 - pharosd not (yet) reachable
*/
int main(int argc, char* argv[])
{
    if (argc != 3)
    {
        std::cerr << "Usage: " << argv[0] << " <host> <port>\n";
        std::cerr << "Specify the version by setting 'PHAROS_VERSION'" << std::endl;
        return 2;
    }

    const char* token = std::getenv("PHAROS_VERSION");

    if (!token)
    {
        std::cerr << "PHAROS_VERSION not set\n";
        return 2;
    }

    int sock = socket(AF_INET, SOCK_STREAM, 0);

    if (sock < 0)
    {
        perror("socket");
        return 2;
    }

    sockaddr_in server{};
    server.sin_family = AF_INET;
    server.sin_port = htons(std::stoi(argv[2]));

    addrinfo hints{};
    addrinfo* res = nullptr;

    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_STREAM;

    int err = getaddrinfo(argv[1], argv[2], &hints, &res);
    if (err != 0)
    {
        std::cerr << "getaddrinfo: " << gai_strerror(err) << "\n";
        close(sock);
        return 3;
    }

    if (connect(sock, res->ai_addr, res->ai_addrlen) < 0)
    {
        perror("connect");
        freeaddrinfo(res);
        close(sock);
        return 2;
    }

    freeaddrinfo(res);
    std::string request = std::string(token) + "\n";

    if (send(sock, request.c_str(), request.size(), 0) < 0)
    {
        perror("send");
        close(sock);
        return 3;
    }

    timeval tv{};
    tv.tv_sec = 5;
    tv.tv_usec = 0;

    setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));

    char buffer[1024];
    ssize_t n = recv(sock, buffer, sizeof(buffer) - 1, 0);

    if (n < 0)
    {
        perror("recv");
        close(sock);
        return 3;
    }

    buffer[n] = '\0';

    std::string response(buffer);

    std::cout << response;

    close(sock);

    if (response.rfind("OK", 0) == 0)
        return 0;

    return 1;
}
