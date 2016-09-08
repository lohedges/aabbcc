%module aabb

%{
#include "../src/AABB.h"
%}

%include "../src/AABB.h"
%include "std_vector.i"

namespace std {
   %template(BoolVector) vector<bool>;
   %template(DoubleVector) vector<double>;
   %template(UnsignedIntVector) vector<unsigned int>;
};
