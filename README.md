# BSR: B-spline atomic R-matrix codes

BSR is a general program to calculate atomic continuum processes using
the B-spline R-matrix method, including electron-atom and electron-ion
scattering, and radiative processes such as bound-bound transitions,
photoionization and polarizabilities. The calculations can be
performed in LS-coupling or in an intermediate-coupling scheme by
including terms of the Breit-Pauli Hamiltonian.

The present version is the deep recomposition of the original version
published in

      >  Computer Physics Communications 174 (2006) 273–356

Numerous new features and extansions are added, see doc folder in this
repository and the references:

* Atomic structure calculations using MCHF and BSR
  >Oleg Zatsarinny and Charlotte Froese Fischer
  >Computer Physics Communications 180 (2009) 2041–2065

* The B-spline R-matrix method for atomic processes:
  application to atomic structure, electron collisions and photoionization
  >Oleg Zatsarinny and Klaus Bartschat
  >J. Phys. B: At. Mol. Opt. Phys. 46 (2013) 112001

## DBSR - Dirac-based fully-relativistic B-spline atomic R-matrix codes

DBSR is a general program to calculate atomic continuum processes
using the B-spline R-matrix method, including electron-atom and
electron-ion scattering, and radiative processes such as bound-bound
transitions, photoionization and polarizabilities. The calculations
are performed in jj-coupling scheme using the Dirac-Coulomb-Breit
Hamiltonian.

# Build instructions

Building BSR requires

- [CMake](https://cmake.org/) (at least version 3.13)
- A working Fortran compiler (tested with `gfortran` 9.3)
- A BLAS/LAPACK installation
- Optionally, a MPI implementation (tested with OpenMPI). If found,
  MPI versions of some of the codes are also built.

When these requirements are fulfilled, building BSR is very
easy. Create a `build/` subdirectory, and compile from there:

```bash
/path/to/bsr $ mkdir build && cd build

/path/to/bsr/build $ FC=gfortran cmake ../src/
-- The C compiler identification is AppleClang 11.0.0.11000033
-- The CXX compiler identification is AppleClang 11.0.0.11000033
...

/path/to/bsr/build $ make
```

(Multithreaded build with `make -jN` does not work with Fortran
modules interdependencies).

All executables can then be found under `build/bin/`.
