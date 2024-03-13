#include "mylib/lib.hpp"

int main() {  // NOLINT(bugprone-exception-escape)
  return some_fun() == EXPECTED_RESULT ? 0 : 1;
}