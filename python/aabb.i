%module aabb

%{
#include "../src/AABB.h"
%}

%include "../src/AABB.h"
%include "std_vector.i"

namespace std {
   %template(VectorBool) vector<bool>;
   %template(VectorDouble) vector<double>;
   %template(VectorUnsignedInt) vector<unsigned int>;
};
