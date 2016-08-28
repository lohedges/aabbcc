/*
  Copyright (c) 2015-2016 Lester Hedges <lester.hedges+vmmc@gmail.com>

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

#ifndef _MERSENNETWISTER_H
#define _MERSENNETWISTER_H

#include <random>

/*! \file MersenneTwister.h
    \brief A C++11 implementation of a Mersenne-Twister
    random number generator class.
*/

//! Mersenne-Twister class.
class MersenneTwister
{
public:
    //! Constructor.
    MersenneTwister()
    {
        // Get a hardware random number and seed the generator.
        seed = std::random_device{}();
        generator.seed(seed);

        /* Note that seeding the generator with a single 32-bit integer
           only allows for 2^32 initial states.

          For a better RNG, consider using the Permuted Congruential Generator

            http://www.pcg-random.org

          For details on the pitfalls of seeding the C++11 mt19937 generator,
          see

            http://www.pcg-random.org/posts/cpp-seeding-surprises.html

          To enable good seeding with mt19937, consider using randutils.hpp

            https://gist.github.com/imneme/540829265469e673d045
         */
    }

    //! Overloaded () operator.
    /*! \return A uniform random double in range [0-1]. */
    double operator()()
    {
        return default_uniform_real_distribution(generator);
    }

    //! Generate a random integer between min and max (inclusive).
    /*! \param min
            The minium of the range.

        \param max
            The maxium of the range.

        \return
            The uniform random integer.
     */
    int integer(int min, int max)
    {
        return std::uniform_int_distribution<int>{min, max}(generator);
    }

    //! Generate a random number from a normal distribution with
    /*! zero mean and unit standard deviation.
        \return
            A random number drawn from the normal distribution.
     */
    double normal()
    {
        return default_normal_distribution(generator);
    }

    //! Generate a random number from a normal distribution.
    /*! \param mean
            The mean of the the normal distribution.

        \param stdDev
            The standard deviation of the normal distribution.

        \return
            A random number drawn from the normal distribution.
     */
    double normal(double mean, double stdDev)
    {
        return std::normal_distribution<double>{mean, stdDev}(generator);
    }

    //! Get the random number generator seed.
    /*! \return seed
            The generator seed.
     */
    unsigned int getSeed()
    {
        return seed;
    }

    //! Seed the random number generator.
    /*! \param seed_
            The new seed.
     */
    void setSeed(unsigned int seed_)
    {
        seed = seed_;
        generator.seed(seed);
    }

private:
    /// The Mersenne-Twister generator.
    std::mt19937 generator;

    /// Default uniform_real distribution [0-1].
    std::uniform_real_distribution<double> default_uniform_real_distribution{0.0, 1.0};

    /// Default normal distribution with zero mean and unit standard deviation.
    std::normal_distribution<double> default_normal_distribution{0.0, 1.0};

    /// The random number seed.
    unsigned int seed;
};

#endif  /* _MERSENNETWISTER_H */
