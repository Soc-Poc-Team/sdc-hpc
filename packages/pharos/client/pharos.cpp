#include <arpa/inet.h>
#include <cstdlib>
#include <cstring>
#include <iostream>
#include <string>
#include <sys/socket.h>
#include <unistd.h>
#include <sys/types.h>
#include <netdb.h>
#include <fcntl.h>
#include <cerrno>

/*
Exit codes:
0 - pharosd ok
1 - pharosd no
2 - usage error
3 - pharosd not (yet) reachable
*/

static bool connect_with_timeout(int sock,
                                 const sockaddr* addr,
                                 socklen_t len,
                                 int timeout_sec)
{
    int flags = fcntl(sock, F_GETFL, 0);
    fcntl(sock, F_SETFL, flags | O_NONBLOCK);

    int res = connect(sock, addr, len);

    if (res == 0)
    {
        fcntl(sock, F_SETFL, flags);
        return true;
    }

    if (errno != EINPROGRESS)
        return false;

    fd_set wfds;
    FD_ZERO(&wfds);
    FD_SET(sock, &wfds);

    timeval tv{};
    tv.tv_sec = timeout_sec;
    tv.tv_usec = 0;

    res = select(sock + 1, nullptr, &wfds, nullptr, &tv);

    if (res <= 0)
    {
        fcntl(sock, F_SETFL, flags);
        return false;
    }

    int err = 0;
    socklen_t errlen = sizeof(err);

    if (getsockopt(sock, SOL_SOCKET, SO_ERROR, &err, &errlen) < 0)
    {
        fcntl(sock, F_SETFL, flags);
        return false;
    }

    fcntl(sock, F_SETFL, flags);

    return err == 0;
}

int main(int argc, char* argv[])
{
    if (argc != 3)
    {
        std::cerr << "Употреба: " << argv[0] << " <host> <port>\n";
        std::cerr << "Посочете версията чрез задаване на 'PHAROS_VERSION'\n";
        return 2;
    }

    const char* token = std::getenv("PHAROS_VERSION");

    if (!token)
    {
        std::cerr << "PHAROS_VERSION не е зададен\n";
        return 2;
    }

    int sock = socket(AF_INET, SOCK_STREAM, 0);

    if (sock < 0)
    {
        perror("socket");
        return 3;
    }

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

    bool connected = false;

    for (addrinfo* p = res; p != nullptr; p = p->ai_next)
    {
        if (connect_with_timeout(sock, p->ai_addr, p->ai_addrlen, 2))
        {
            connected = true;
            break;
        }
    }

    freeaddrinfo(res);

    if (!connected)
    {
        std::cerr << "connect timeout/failure\n";
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

    timeval tv{};
    tv.tv_sec = 5;
    tv.tv_usec = 0;

    setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));

    char buffer[1024] = {0};

    ssize_t n = recv(sock, buffer, sizeof(buffer) - 1, 0);

    if (n <= 0)
    {
        std::cerr << "recv failed or closed\n";
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
