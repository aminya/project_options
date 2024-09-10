#include "mylib/lib.hpp"

// test external pac
#include <fmt/core.h>
#include <fmt/ranges.h>

#ifdef HAS_EIGEN
#    include <Eigen/Dense>
#endif

// test std libraries
#include <iostream>
#include <string>
#include <string_view>
#include <vector>

// test c libraries
#include <cassert>
#include <cctype>
#include <cstddef>
#include <cstdint>
#include <cstring>

int main()
{
    fmt::print("Hello from main{}\n", "!");

    auto eigen_vec = std::vector<int>() = {1, 2, 3};
    fmt::print("[{}]\n", fmt::join(eigen_vec, ", "));

#if defined(HAS_EIGEN) && !defined(__MINGW32__) && !defined(__MSYS__) // TODO fails
    Eigen::VectorXd eigen_vec2 = Eigen::VectorXd::LinSpaced(10, 0, 1);
    fmt::print("[{}]\n", fmt::join(eigen_vec2, ", "));
#endif

    // trigger address sanitizer
    // int *p = nullptr;
    // *p = 1;

    // trigger compiler warnings, clang-tidy, and cppcheck
    int a = some_fun();
}
