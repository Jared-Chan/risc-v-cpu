#include <chrono>
#include <fstream>
#include <iostream>
#include <string>
#include <thread>
#include <unistd.h>

int main() {
    std::ofstream outf{"mock_uart_input.txt"};

    if (!outf) {
        std::cerr << "Could not open outf";
        return 1;
    }

    std::ifstream inf{"mock_uart_output.txt"};

    if (!inf) {
        std::cerr << "Could not open inf";
        return 1;
    }

    int no_input_count = 0;

    std::string user_input{};
    std::string uart_output{};
    while (true) {
        if (no_input_count < 10) {
            if (std::getline(inf, uart_output)) {
                std::cout << uart_output << '\n';
                no_input_count = 0;
            } else {
                std::this_thread::sleep_for(std::chrono::milliseconds(100));
                inf.clear();
                inf.sync();
                ++no_input_count;
            }
        } else {
            std::cout << "> ";
            getline(std::cin, user_input);
            outf << user_input << std::endl;
            no_input_count = 0;
        }
    }

    return 0;
}
