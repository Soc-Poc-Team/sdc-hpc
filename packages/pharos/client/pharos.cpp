#include <arpa/inet.h>
#include <cstdlib>
#include <cstring>
#include <iostream>
#include <string>
#include <sys/socket.h>
#include <unistd.h>

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

    if (inet_pton(AF_INET, argv[1], &server.sin_addr) != 1)
    {
        std::cerr << "Invalid address\n";
        close(sock);
        return 2;
    }

    if (connect(sock, reinterpret_cast<sockaddr*>(&server), sizeof(server)) < 0)
    {
        perror("connect");
        close(sock);
        return 3;
    }

    std::string request = std::string(token) + "\n";

    if (send(sock, request.c_str(), request.size(), 0) < 0)
    {
        perror("send");
        close(sock);
        return 3;
    }

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
