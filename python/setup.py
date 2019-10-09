#!/usr/bin/env python

"""
setup.py file for the AABB.cc python interface.
"""

from distutils.core import setup, Extension

aabb_module = Extension('_aabb',
                         sources = ['aabb_wrap.cxx', '../src/AABB.cc'],
                         extra_compile_args = ["-O3", "-std=c++11"], 
                        )

setup (name = 'aabb',
       author = 'Lester Hedges',
       author_email = 'lester.hedges+aabbcc@gmail.com',
       description = 'AABB.cc python wrapper',
       ext_modules = [aabb_module],
       py_modules = ['aabb'],
       url = 'http://github.com/lohedges/aabbcc',
       license = 'Zlib',
       )
