#include "Foo.hpp"

namespace mythirdpartylib {

void Foo::update(bool b, bool c, bool d) {
  int e = b + d;
  m_a = e;
}

void Foo::bad(std::vector<std::string> &v) {
  std::string val = "hello";
  int index = -1; // bad, plus should use gsl::index
  for (int i = 0; i < v.size(); ++i) {
    if (v[i] == val) {
      index = i;
      break;
    }
  }
}

static Foo foo(5);
static Foo bar = 42;

} // namespace mythirdpartylib