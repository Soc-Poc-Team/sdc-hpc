#include <arpa/inet.h>
#include <cstring>
#include <fstream>
#include <iostream>
#include <string>
#include <sys/socket.h>
#include <unistd.h>
#include <unordered_set>

static std::unordered_set<std::string> load_file(const std::string& path)
{
    std::unordered_set<std::string> set;
    std::ifstream file(path);

    std::string line;
    while (std::getline(file, line))
    {
        if (!line.empty())
            set.insert(line);
    }

    return set;
}

static std::string trim_newline(std::string s)
{
    while (!s.empty() && (s.back() == '\n' || s.back() == '\r'))
        s.pop_back();
    return s;
}

static void handle_client(int client_fd,
                          const std::unordered_set<std::string>& allowed)
{
    char buffer[1024];

    ssize_t n = recv(client_fd, buffer, sizeof(buffer) - 1, 0);
    if (n <= 0)
        return;

    buffer[n] = '\0';

    std::string request(buffer);
    request = trim_newline(request);

    std::string response;

    if (allowed.contains(request))
        response = "OK\n";
    else
        response = "NO\n";

    send(client_fd, response.c_str(), response.size(), 0);
}

int main(int argc, char* argv[])
{
    if (argc != 3)
    {
        std::cerr << "Usage: " << argv[0] << " <port> <file>\n";
        return 1;
    }

    int port = std::stoi(argv[1]);
    std::string file_path = argv[2];

    auto allowed = load_file(file_path);

    int server_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (server_fd < 0)
    {
        perror("socket");
        return 1;
    }

    int opt = 1;
    setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

    sockaddr_in addr{};
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = INADDR_ANY;
    addr.sin_port = htons(port);

    if (bind(server_fd, reinterpret_cast<sockaddr*>(&addr), sizeof(addr)) < 0)
    {
        perror("bind");
        close(server_fd);
        return 1;
    }

    if (listen(server_fd, 10) < 0)
    {
        perror("listen");
        close(server_fd);
        return 1;
    }

    std::cout << "Pharosd running on port " << port << "\n";

    while (true)
    {
        sockaddr_in client_addr{};
        socklen_t client_len = sizeof(client_addr);

        int client_fd = accept(server_fd,
                               reinterpret_cast<sockaddr*>(&client_addr),
                               &client_len);

        if (client_fd < 0)
            continue;

        handle_client(client_fd, allowed);

        close(client_fd);
    }

    close(server_fd);
    return 0;
}
