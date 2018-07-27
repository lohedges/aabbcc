%module aabb

%{
#include "../src/AABB.h"
%}

%include "std_vector.i"

namespace std {
  %template(VectorBool) vector<bool>;
  %template(VectorDouble) vector<double>;
  %template(VectorUnsignedInt) vector<unsigned int>;
};

%include "exception.i"

%exception {
  try {
    $action
  }
  catch (const std::invalid_argument& e) {
    SWIG_exception(SWIG_ValueError, e.what());
  }
}

%include "../src/AABB.h"
