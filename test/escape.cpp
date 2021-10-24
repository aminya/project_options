// Copyright 2017 The Abseil Authors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// NOT used! CK #include "absl/strings/escaping.h"

#include <cassert>// for assert
#include <cctype>// for isxdigit, isprint
#include <cstddef>// for ptrdiff_t
#include <cstring>// for memmove
#include <iostream>// for operator<<, string, basic_ostream, endl, cout
#include <string>// for char_traits, operator+, allocator, operator""s
#include <string_view>// for string_view, basic_string_view

namespace numbers_internal {
constexpr char kHexChar[] = { "0123456789ABCDEF" };
}

namespace {

// These are used for the leave_nulls_escaped argument to CUnescapeInternal().
constexpr bool kUnescapeNulls = false;

inline bool is_octal_digit(char c) { return ('0' <= c) && (c <= '7'); }

inline int hex_digit_to_int(char c) {
    static_assert('0' == 0x30 && 'A' == 0x41 && 'a' == 0x61,
      "Character set must be ASCII.");
    assert(std::isxdigit(c));
    int x = static_cast<unsigned char>(c);
    if (x > '9') { x += 9; }
    return x & 0xf;
}

// ----------------------------------------------------------------------
// CUnescapeInternal()
//    Implements both CUnescape() and CUnescapeForNullTerminatedString().
//
//    Unescapes C escape sequences and is the reverse of CEscape().
//
//    If 'source' is valid, stores the unescaped string and its size in
//    'dest' and 'dest_len' respectively, and returns true. Otherwise
//    returns false and optionally stores the error description in
//    'error'. Set 'error' to nullptr to disable error reporting.
//
//    'dest' should point to a buffer that is at least as big as 'source'.
//    'source' and 'dest' may be the same.
//
//     NOTE: any changes to this function must also be reflected in the older
//     UnescapeCEscapeSequences().
// ----------------------------------------------------------------------
bool CUnescapeInternal(std::string_view source,
  bool leave_nulls_escaped,
  char *dest,
  ptrdiff_t *dest_len,
  std::string *error) {
    char *d = dest;
    const char *p = source.data();
    const char *end = p + source.size();
    const char *last_byte = end - 1;

    // Small optimization for case where source = dest and there's no escaping
    while (p == d && p < end && *p != '\\') { p++, d++; }

    while (p < end) {
        if (*p != '\\') {
            *d++ = *p++;
        } else {
            if (++p > last_byte) {// skip past the '\\'
                if (error) { *error = "String cannot end with \\"; }
                return false;
            }
            switch (*p) {
            case 'a':
                *d++ = '\a';
                break;
            case 'b':
                *d++ = '\b';
                break;
            case 'f':
                *d++ = '\f';
                break;
            case 'n':
                *d++ = '\n';
                break;
            case 'r':
                *d++ = '\r';
                break;
            case 't':
                *d++ = '\t';
                break;
            case 'v':
                *d++ = '\v';
                break;
            case '\\':
                *d++ = '\\';
                break;
            case '?':
                *d++ = '\?';
                break;// \?  Who knew?
            case '\'':
                *d++ = '\'';
                break;
            case '"':
                *d++ = '\"';
                break;
            case '0':
            case '1':
            case '2':
            case '3':
            case '4':
            case '5':
            case '6':
            case '7': {
                // octal digit: 1 to 3 digits
                const char *octal_start = p;
                unsigned int ch = *p - '0';
                if (p < last_byte && is_octal_digit(p[1])) {
                    ch = ch * 8 + *++p - '0';
                }
                if (p < last_byte && is_octal_digit(p[1])) {
                    ch = ch * 8 + *++p - '0';// now points at last digit
                }
                if (ch > 0xff) {
                    if (error) {
                        *error = "Value of \\" + std::string(octal_start, p + 1 - octal_start) + " exceeds 0xff";
                    }
                    return false;
                }
                if ((ch == 0) && leave_nulls_escaped) {
                    // Copy the escape sequence for the null character
                    const ptrdiff_t octal_size = p + 1 - octal_start;
                    *d++ = '\\';
                    std::memmove(d, octal_start, octal_size);
                    d += octal_size;
                    break;
                }
                *d++ = ch;
                break;
            }
            case 'x':
            case 'X': {
                if (p >= last_byte) {
                    if (error) { *error = "String cannot end with \\x"; }
                    return false;
                } else if (!std::isxdigit(p[1])) {
                    if (error) { *error = "\\x cannot be followed by a non-hex digit"; }
                    return false;
                }
                unsigned int ch = 0;
                const char *hex_start = p;
                while (p < last_byte && std::isxdigit(p[1])) {
                    // Arbitrarily many hex digits
                    ch = (ch << 4) + hex_digit_to_int(*++p);
                }
                if (ch > 0xFF) {
                    if (error) {
                        *error = "Value of \\" + std::string(hex_start, p + 1 - hex_start) + " exceeds 0xff";
                    }
                    return false;
                }
                if ((ch == 0) && leave_nulls_escaped) {
                    // Copy the escape sequence for the null character
                    const ptrdiff_t hex_size = p + 1 - hex_start;
                    *d++ = '\\';
                    std::memmove(d, hex_start, hex_size);
                    d += hex_size;
                    break;
                }
                *d++ = ch;
                break;
            }

#if 0
        case 'u': {
          // \uhhhh => convert 4 hex digits to UTF-8
          char32_t rune = 0;
          const char* hex_start = p;
          if (p + 4 >= end) {
            if (error) {
              *error = "\\u must be followed by 4 hex digits: \\" +
                       std::string(hex_start, p + 1 - hex_start);
            }
            return false;
          }
          for (int i = 0; i < 4; ++i) {
            // Look one char ahead.
            if (absl::ascii_isxdigit(p[1])) {
              rune = (rune << 4) + hex_digit_to_int(*++p);  // Advance p.
            } else {
              if (error) {
                *error = "\\u must be followed by 4 hex digits: \\" +
                         std::string(hex_start, p + 1 - hex_start);
              }
              return false;
            }
          }
          if ((rune == 0) && leave_nulls_escaped) {
            // Copy the escape sequence for the null character
            *d++ = '\\';
            std::memmove(d, hex_start, 5);  // u0000
            d += 5;
            break;
          }
          if (IsSurrogate(rune, absl::string_view(hex_start, 5), error)) {
            return false;
          }
          d += strings_internal::EncodeUTF8Char(d, rune);
          break;
        }
        case 'U': {
          // \Uhhhhhhhh => convert 8 hex digits to UTF-8
          char32_t rune = 0;
          const char* hex_start = p;
          if (p + 8 >= end) {
            if (error) {
              *error = "\\U must be followed by 8 hex digits: \\" +
                       std::string(hex_start, p + 1 - hex_start);
            }
            return false;
          }
          for (int i = 0; i < 8; ++i) {
            // Look one char ahead.
            if (absl::ascii_isxdigit(p[1])) {
              // Don't change rune until we're sure this
              // is within the Unicode limit, but do advance p.
              uint32_t newrune = (rune << 4) + hex_digit_to_int(*++p);
              if (newrune > 0x10FFFF) {
                if (error) {
                  *error = "Value of \\" +
                           std::string(hex_start, p + 1 - hex_start) +
                           " exceeds Unicode limit (0x10FFFF)";
                }
                return false;
              } else {
                rune = newrune;
              }
            } else {
              if (error) {
                *error = "\\U must be followed by 8 hex digits: \\" +
                         std::string(hex_start, p + 1 - hex_start);
              }
              return false;
            }
          }
          if ((rune == 0) && leave_nulls_escaped) {
            // Copy the escape sequence for the null character
            *d++ = '\\';
            std::memmove(d, hex_start, 9);  // U00000000
            d += 9;
            break;
          }
          if (IsSurrogate(rune, absl::string_view(hex_start, 9), error)) {
            return false;
          }
          d += strings_internal::EncodeUTF8Char(d, rune);
          break;
        }
#endif

            default: {
                if (error) {
                    *error = std::string("Unknown escape sequence: \\") + *p;
                }
                return false;
            }
            }
            p++;// read past letter we escaped
        }
    }
    *dest_len = d - dest;
    return true;
}

// ----------------------------------------------------------------------
// CUnescapeInternal()
//
//    Same as above but uses a std::string for output. 'source' and 'dest'
//    may be the same.
// ----------------------------------------------------------------------
bool CUnescapeInternal(std::string_view source,
  bool leave_nulls_escaped,
  std::string *dest,
  std::string *error) {
    // XXX strings_internal::STLStringResizeUninitialized(dest, source.size());
    dest->resize(source.size());

    ptrdiff_t dest_size;
    if (!CUnescapeInternal(source,
          leave_nulls_escaped,
          &(*dest)[0],
          &dest_size,
          error)) {
        return false;
    }
    dest->erase(dest_size);
    return true;
}

// ----------------------------------------------------------------------
// CEscape()
// CHexEscape()
// Utf8SafeCEscape()
// Utf8SafeCHexEscape()
//    Escapes 'src' using C-style escape sequences.  This is useful for
//    preparing query flags.  The 'Hex' version uses hexadecimal rather than
//    octal sequences.  The 'Utf8Safe' version does not touch UTF-8 bytes.
//
//    Escaped chars: \n, \r, \t, ", ', \, and !std::ascii_isprint().
// ----------------------------------------------------------------------
std::string CEscapeInternal(std::string_view src,
  bool use_hex,
  bool utf8_safe) {
    std::string dest;
    bool last_hex_escape = false;// true if last output char was \xNN.

    for (unsigned char c : src) {
        bool is_hex_escape = false;
        switch (c) {
        case '\n':
            dest.append("\\n");
            break;
        case '\r':
            dest.append("\\r");
            break;
        case '\t':
            dest.append("\\t");
            break;
        case '\"':
            dest.append("\\\"");
            break;
        case '\'':
            dest.append("\\'");
            break;
        case '\\':
            dest.append("\\\\");
            break;
        default:
            // Note that if we emit \xNN and the src character after that is a hex
            // digit then that digit must be escaped too to prevent it being
            // interpreted as part of the character code by C.
            if ((!utf8_safe || c < 0x80) && (!std::isprint(c) || (last_hex_escape && std::isxdigit(c)))) {
                if (use_hex) {
                    dest.append("\\u00");
                    dest.push_back(numbers_internal::kHexChar[c / 16]);
                    dest.push_back(numbers_internal::kHexChar[c % 16]);
                    is_hex_escape = true;
                } else {
                    dest.append("\\");
                    dest.push_back(numbers_internal::kHexChar[c / 64]);
                    dest.push_back(numbers_internal::kHexChar[(c % 64) / 8]);
                    dest.push_back(numbers_internal::kHexChar[c % 8]);
                }
            } else {
                dest.push_back(c);
                break;
            }
        }
        last_hex_escape = is_hex_escape;
    }

    return dest;
}

// ----------------------------------------------------------------------
// CUnescape()
//
// See CUnescapeInternal() for implementation details.
// ----------------------------------------------------------------------
bool CUnescape(std::string_view source, std::string *dest, std::string *error) {
    return CUnescapeInternal(source, kUnescapeNulls, dest, error);
}

std::string CEscape(std::string_view src) {
    return CEscapeInternal(src, false, false);
}

std::string CHexEscape(std::string_view src) {
    return CEscapeInternal(src, true, false);
}

std::string Utf8SafeCEscape(std::string_view src) {
    return CEscapeInternal(src, false, true);
}

std::string Utf8SafeCHexEscape(std::string_view src) {
    return CEscapeInternal(src, true, true);
}

}// namespace

int main() {
    using namespace std::string_literals;

    const std::string test{
        "\t\n\xF0\x91\xA2\xA1\x3D\xC4\xB3\xF0\x9B\x84\x9B\xEF\xBD\xA7"
    };
    const std::string utf8{ "\0\xFE\x80\x22\xF0\x9F\x8D\x8C\x22\n"s };
    const std::string in{
        "This\nis\na\ntest\n\nShe said, \"Sells she seashells on the seashore?\"\n"s
    };

    std::cout << in << std::endl;
    std::string out = CHexEscape(in);

    std::cout << '"' << CEscape(test) << '"' << std::endl;
    std::cout << '"' << CHexEscape(test) << '"' << std::endl;
    std::cout << '"' << CEscape(utf8) << '"' << std::endl;
    std::cout << '"' << CHexEscape(utf8) << '"' << std::endl;

    std::cout << '"' << CEscape(in) << '"' << std::endl;
    std::cout << '"' << out << '"' << std::endl;
    std::cout << '"' << Utf8SafeCEscape(in) << '"' << std::endl;
    std::cout << '"' << Utf8SafeCHexEscape(in) << '"' << std::endl;

    std::string result;
    std::string err;
    if (CUnescape(out, &result, &err)) {
        std::cout << '"' << result << '"' << std::endl;
    } else {
        std::cout << err << std::endl;
    }
}
