// test external pac
#include <Eigen/Dense>
#include <fmt/core.h>
#include <fmt/ostream.h>

// test std libraries
#include <iostream>
#include <string>
#include <string_view>

// test c libraries
#include <cassert>
#include <cctype>
#include <cstddef>
#include <cstdint>
#include <cstring>

int main() {
    fmt::print("Hello from fmt{}", "!");

    Eigen::VectorXd eigen_vec = Eigen::Vector3d(1, 2, 3);
    fmt::print("{}", eigen_vec);

#if !defined(__MINGW32__) && !defined(__MSYS__)// TODO fails
    Eigen::VectorXd eigen_vec2 = Eigen::VectorXd::LinSpaced(10, 0, 1);
    fmt::print("{}", eigen_vec2);
#endif

    // trigger address sanitizer
    // int *p = nullptr;
    // *p = 1;

    // trigger compiler warnings, clang-tidy, and cppcheck
    int a;
}
