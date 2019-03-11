#!/usr/bin/env python2

# Copyright (c) 2016-2018 Lester Hedges <lester.hedges+aabbcc@gmail.com>
#
# This software is provided 'as-is', without any express or implied
# warranty. In no event will the authors be held liable for any damages
# arising from the use of this software.

# Permission is granted to anyone to use this software for any purpose,
# including commercial applications, and to alter it and redistribute it
# freely, subject to the following restrictions:
#
# 1. The origin of this software must not be misrepresented; you must not
#    claim that you wrote the original software. If you use this software
#    in a product, an acknowledgment in the product documentation would be
#    appreciated but is not required.
#
# 2. Altered source versions must be plainly marked as such, and must not be
#    misrepresented as being the original software.
#
# 3. This notice may not be removed or altered from any source distribution.

"""An example showing how to use the AABB.cc Python wrapper."""

# Note:
# SWIG allows us direct access to STL vectors in python. See aabb.i for
# full details of the mappings.
#
# As an example, you can create a STL vector containing 10 doubles
# as follows:
#
#       doubleVector = aabb.VectorDouble(10)
#
# You can then access most of the usual member functions, e.g. to
# print the size of the vector:
#
#       print doubleVector.size()

from __future__ import print_function

import aabb
import math
import random

# Test whether two discs overlap.
def overlaps(position1, position2, periodicity, boxSize, cutOff):
    # Compute separation vector.
    separation = [0] * 2
    separation[0] = position1[0] - position2[0]
    separation[1] = position1[1] - position2[1]

    # Find minimum image separation.
    minimumImage(separation, periodicity, boxSize)

    # Squared distance between objects.
    rSqd = separation[0]*separation[0] + separation[1]*separation[1]

    if rSqd < cutOff:
        return True
    else:
        return False

# Compute the minimum image separation vector between disc centres.
def minimumImage(separation, periodicity, boxSize):
    for i in range(0, 2):
        if separation[i] < -0.5*boxSize[i]:
            separation[i] += periodicity[i]*boxSize[i]
        elif separation[i] >= 0.5*boxSize[i]:
            separation[i] -= periodicity[i]*boxSize[i]

# Apply periodic boundary conditions.
def periodicBoundaries(position, periodicity, boxSize):
    for i in range(0, 2):
        if position[i] < 0:
            position[i] += periodicity[i]*boxSize[i]
        elif position[i] >= boxSize[i]:
            position[i] -= periodicity[i]*boxSize[i]

# Print current configuration to VMD trajectory file.
def printVMD(fileName, positionsSmall, positionsLarge):
    with open(fileName, 'a') as trajectoryFile:
        trajectoryFile.write('%lu\n' % (len(positionsSmall) + len(positionsLarge)))
        trajectoryFile.write('\n')
        for i in range(0, len(positionsSmall)):
            trajectoryFile.write('0 %lf %lf 0\n' % (positionsSmall[i][0], positionsSmall[i][1]))
        for i in range(0, len(positionsLarge)):
            trajectoryFile.write('1 %lf %lf 0\n' % (positionsLarge[i][0], positionsLarge[i][1]))

#############################################################
#     Set parameters, initialise variables and objects.     #
#############################################################

nSweeps = 100000        # The number of Monte Carlo sweeps.
sampleInterval = 100    # The number of sweeps per sample.
nSmall = 1000           # The number of small particles.
nLarge = 100            # The number of large particles.
diameterSmall = 1       # The diameter of the small particles.
diameterLarge = 10      # The diameter of the large particles.
density = 0.1           # The system density
maxDisp = 0.1           # Maximum trial displacement (in units of diameter).

# Total particles.
nParticles = nSmall + nLarge

# Number of samples.
nSamples = math.floor(nSweeps / sampleInterval)

# Particle radii.
radiusSmall = 0.5 * diameterSmall
radiusLarge = 0.5 * diameterLarge

# Output formatting flag.
format = int(math.floor(math.log10(nSamples)))

# Set the periodicity of the simulation box.
periodicity = aabb.VectorBool(2)
periodicity[0] = True
periodicity[1] = True

# Work out base length of the simulation box.
baseLength = math.pow((math.pi*(nSmall*diameterSmall + nLarge*diameterLarge))/(4*density), 0.5)
boxSize = aabb.VectorDouble(2)
boxSize[0] = baseLength
boxSize[1] = baseLength

# Seed the random number generator.
random.seed()

# Initialise the AABB trees.
treeSmall = aabb.Tree(2, maxDisp, periodicity, boxSize, nSmall)
treeLarge = aabb.Tree(2, maxDisp, periodicity, boxSize, nLarge)

# Initialise particle position vectors.
positionsSmall = [[0 for i in range(2)] for j in range(nSmall)]
positionsLarge = [[0 for i in range(2)] for j in range(nLarge)]

#############################################################
#             Generate the initial AABB trees.              #
#############################################################

# First the large particles.
print('Inserting large particles into AABB tree ...')

# Cut-off distance.
cutOff = 2 * radiusLarge
cutOff *= cutOff

# Initialise the position vector.
position = aabb.VectorDouble(2)

# Initialise bounds vectors.
lowerBound = aabb.VectorDouble(2)
upperBound = aabb.VectorDouble(2)

for i in range(0, nLarge):
    # Insert the first particle directly.
    if i == 0:
        # Generate a random particle position.
        position[0] = boxSize[0]*random.random()
        position[1] = boxSize[1]*random.random()

    # Check for overlaps.
    else:
        # Initialise the overlap flag.
        isOverlap = True

        while isOverlap:
            # Generate a random particle position.
            position[0] = boxSize[0]*random.random()
            position[1] = boxSize[1]*random.random()

            # Compute the lower and upper AABB bounds.
            lowerBound[0] = position[0] - radiusLarge
            lowerBound[1] = position[1] - radiusLarge
            upperBound[0] = position[0] + radiusLarge
            upperBound[1] = position[1] + radiusLarge

            # Generate the AABB.
            AABB = aabb.AABB(lowerBound, upperBound)

            # Query AABB overlaps.
            particles = treeLarge.query(AABB)

            # Flag as no overlap (yet).
            isOverlap = False

            # Test overlap.
            for j in range(0, len(particles)):
                if overlaps(position, positionsLarge[particles[j]], periodicity, boxSize, cutOff):
                    isOverlap = True
                    break

    # Insert the particle into the tree.
    treeLarge.insertParticle(i, position, radiusLarge)

    # Store the position.
    positionsLarge[i] = [position[0], position[1]]

print('Tree generated!')

# Now fill the gaps with the small particles.

print('\nInserting small particles into AABB tree ...')

for i in range(0, nSmall):
    # Initialise the overlap flag.
    isOverlap = True

    # Keep trying until there is no overlap.
    while isOverlap:
        # Set the cut-off.
        cutOff = radiusSmall + radiusLarge
        cutOff *= cutOff

        # Generate a random particle position.
        position[0] = boxSize[0]*random.random()
        position[1] = boxSize[1]*random.random()

        # Compute the lower and upper AABB bounds.
        lowerBound[0] = position[0] - radiusSmall
        lowerBound[1] = position[1] - radiusSmall
        upperBound[0] = position[0] + radiusSmall
        upperBound[1] = position[1] + radiusSmall

        # Generate the AABB.
        AABB = aabb.AABB(lowerBound, upperBound)

        # First query AABB overlaps with the large particles.
        particles = treeLarge.query(AABB)

        # Flag as no overlap (yet).
        isOverlap = False

        # Test overlap.
        for j in range(0, len(particles)):
            if overlaps(position, positionsLarge[particles[j]], periodicity, boxSize, cutOff):
                isOverlap = True
                break

        # Advance to next overlap test.
        if not isOverlap:
            # Set the cut-off.
            cutOff = radiusSmall + radiusSmall
            cutOff *= cutOff

            # No need to test the first particle.
            if i > 0:
                # Now query AABB overlaps with other small particles.
                particles = treeSmall.query(AABB)

                # Test overlap.
                for j in range(0, len(particles)):
                    if overlaps(position, positionsSmall[particles[j]], periodicity, boxSize, cutOff):
                        isOverlap = True
                        break

    # Insert the particle into the tree.
    treeSmall.insertParticle(i, position, radiusSmall)

    # Store the position.
    positionsSmall[i] = [position[0], position[1]]

print('Tree generated!')

#############################################################
#     Perform the dynamics, updating the tree as we go.     #
#############################################################

# Clear the trajectory file.
open('trajectory.xyz', 'w').close()

print('\nRunning dynamics ...')

sampleFlag = 0
nSampled = 0

# Initialise the displacement vector.
displacement = [0] * 2

for i in range(0, nSweeps):
    for j in range(0, nParticles):
        # Choose a random particle.
        particle = random.randint(0, nParticles-1)

        # Determine the particle type
        if particle < nSmall:
            particleType = 0
            radius = radiusSmall
            displacement[0] = maxDisp*diameterSmall*(2*random.random() - 1)
            displacement[1] = maxDisp*diameterSmall*(2*random.random() - 1)
            position[0] = positionsSmall[particle][0] + displacement[0]
            position[1] = positionsSmall[particle][1] + displacement[1]
        else:
            particleType = 1
            particle -= nSmall
            radius = radiusLarge
            displacement[0] = maxDisp*diameterLarge*(2*random.random() - 1)
            displacement[1] = maxDisp*diameterLarge*(2*random.random() - 1)
            position[0] = positionsLarge[particle][0] + displacement[0]
            position[1] = positionsLarge[particle][1] + displacement[1]

        # Apply periodic boundary conditions.
        periodicBoundaries(position, periodicity, boxSize)

        # Compute the AABB bounds.
        lowerBound[0] = position[0] - radius
        lowerBound[1] = position[1] - radius
        upperBound[0] = position[0] + radius
        upperBound[1] = position[1] + radius

        # Generate the AABB.
        AABB = aabb.AABB(lowerBound, upperBound)

        # Query AABB overlaps with small particles.
        particles = treeSmall.query(AABB)

        # Flag as no overlap (yet).
        isOverlap = False

        # Set the cut-off
        cutOff = radius + radiusSmall
        cutOff *= cutOff

        # Test overlap.
        for k in range(0, len(particles)):
            # Don't test self overlap.
            if particleType == 1 or particles[k] != particle:
                if overlaps(position, positionsSmall[particles[k]], periodicity, boxSize, cutOff):
                    isOverlap = True
                    break

        # Advance to next overlap test.
        if not isOverlap:
            # Now query AABB overlaps with the large particles.
            particles = treeLarge.query(AABB)

            # Set the cut-off.
            cutOff = radius + radiusLarge
            cutOff *= cutOff

            # Test overlap.
            for k in range(0, len(particles)):
                # Don't test self overlap.
                if particleType == 0 or particles[k] != particle:
                    if overlaps(position, positionsLarge[particles[k]], periodicity, boxSize, cutOff):
                        isOverlap = True
                        break

            # Accept the move.
            if not isOverlap:
                # Update the position and AABB tree.
                if particleType == 0:
                    positionsSmall[particle] = [position[0], position[1]]
                    treeSmall.updateParticle(particle, lowerBound, upperBound)
                else:
                    positionsLarge[particle] = [position[0], position[1]]
                    treeLarge.updateParticle(particle, lowerBound, upperBound)

    sampleFlag += 1

    # Print info to screen and append trajectory file.
    if sampleFlag == sampleInterval:
        sampleFlag = 0
        nSampled += 1

        printVMD('trajectory.xyz', positionsSmall, positionsLarge)

        if format == 1:
            print('Saved configuration %2d of %2d' % (nSampled, nSamples))
        elif format == 2:
            print('Saved configuration %3d of %3d' % (nSampled, nSamples))
        elif format == 3:
            print('Saved configuration %4d of %4d' % (nSampled, nSamples))
        elif format == 4:
            print('Saved configuration %5d of %5d' % (nSampled, nSamples))
        elif format == 5:
            print('Saved configuration %6d of %6d' % (nSampled, nSamples))

print('Done!')
