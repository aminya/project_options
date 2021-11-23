// test external pac
#include <fmt/core.h>
#include <fmt/ostream.h>
#include <Eigen/Dense>

// test std libraries
#include <iostream>
#include <string>
#include <string_view>

// test c libraries
#include <cassert>
#include <cctype>
#include <cstddef>
#include <cstring>
#include <cstdint>


int main() {
    fmt::print("Hello from fmt{}", "!");

    // populate an Eigen vector with the values
    auto eigen_vec = Eigen::VectorXd::LinSpaced(10, 0, 1);

    // print the vector
    fmt::print("{}", eigen_vec);

    // trigger address sanitizer
    int *p = nullptr;
    *p = 1;
}
