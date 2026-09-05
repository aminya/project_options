// test external pac
#include <docopt/docopt.h>
#include <Eigen/Dense>
#include <fmt/core.h>
#include <fmt/ostream.h>
#include <fmt/ranges.h>

// test std libraries
#include <iostream>
#include <map>
#include <string>
#include <string_view>

// test c libraries
#include <cassert>
#include <cctype>
#include <cstddef>
#include <cstdint>
#include <cstring>

static std::string const usage{
R"(main.

    Usage:
      main
      main (-h | --help)
      main --version

    Options:
      -h --help     Show this screen.
      --version     Show version.
)"};

int main(int argc, char const* argv[]) {
    std::map<std::string, docopt::value> args{docopt::docopt(usage, {argv + 1, argv + argc}, /*help=*/true, "main 1.0")};
    for (auto const& arg : args) {
      fmt::println("{}: {}", arg.first, fmt::streamed(arg.second));
    }

    Eigen::VectorXd eigen_vec = Eigen::Vector3d(1, 2, 3);
    fmt::println("[{}]", fmt::join(eigen_vec, ", "));

#if !defined(__MINGW32__) && !defined(__MSYS__)// TODO fails
    Eigen::VectorXd eigen_vec2 = Eigen::VectorXd::LinSpaced(10, 0, 1);
    fmt::println("[{}]", fmt::join(eigen_vec2, ", "));
#endif

    // trigger address sanitizer
    // int *p = nullptr;
    // *p = 1;

    // trigger compiler warnings, clang-tidy, and cppcheck
    int a;
}
