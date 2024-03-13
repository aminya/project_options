#include "mylib2/lib.hpp"

int main() {  // NOLINT(bugprone-exception-escape)
  return some_fun2() == EXPECTED_RESULT ? 0 : 1;
}