#pragma once

#include <string>
#include <vector>

#include "mythirdpartylib_export.h"

namespace mythirdpartylib {

class MYTHIRDPARTYLIB_EXPORT Foo {
public:
  Foo() = default;

  /*implicit*/ Foo(int a) : m_a(a) {}

  int a() const { return m_a; }

  void update(bool b, bool c, bool d);
  void bad(std::vector<std::string> &v);

private:
  int m_a;
};

} // namespace mythirdpartylib