#pragma once

// test external pac
#ifdef HAS_EIGEN
#    include <Eigen/Dense>
#else
#    include <vector>
#endif

#include <fmt/core.h>
#include <fmt/ranges.h>

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

int some_fun()
{
    fmt::print("Hello from lib{}\n", "!");

#ifdef HAS_EIGEN
    // populate an Eigen vector with the values
    auto eigen_vec = Eigen::VectorXd::LinSpaced(10, 0, 1);
#else
    auto eigen_vec = std::vector<int>() = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10};
#endif

    // print the vector
    fmt::print("[{}]\n", fmt::join(eigen_vec, ", "));

    return 0;
}
