#include <fmt/core.h>

#include <cassert>// for assert
#include <cctype>// for isxdigit, isprint
#include <cstddef>// for ptrdiff_t
#include <cstring>// for memmove
#include <iostream>// for operator<<, string, basic_ostream, endl, cout
#include <string>// for char_traits, operator+, allocator, operator""s
#include <string_view>// for string_view, basic_string_view

int main() {
    fmt::print("Hello from fmt{}", "!");
}
