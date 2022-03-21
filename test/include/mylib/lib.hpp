#pragma once

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

int some_fun() {
    fmt::print("Hello from fmt{}", "!");

    // populate an Eigen vector with the values
    auto eigen_vec = Eigen::VectorXd::LinSpaced(10, 0, 1);

    // print the vector
    fmt::print("{}", eigen_vec);

    return 0;
}
