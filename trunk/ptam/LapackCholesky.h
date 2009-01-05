// -*- c++ -*-
// Copyright 2008 Isis Innovation Limited

// Wrapper for LAPACK's cholesky-solver routines
// Basically does vInputOutput = mLHS^-1 * vInputOutput
// (I use this for bundle adjustment instead of TooN's hand-rolled c++ cholesky.)
#ifndef __LAPACKCHOL
#define __LAPACKCHOL

#include <TooN/lapack.h>
#include <TooN/TooN.h>

extern "C" void dpotrf_ (char *uplo, int *n, double *a, int *lda, int *info);
extern "C" void	dpotrs_ (char *uplo, int *n, int *nrhs, double *a, int *lda, double *b, int *ldb, int *info);

inline bool LapackCholeskySolve_ReplaceArgs(Matrix<> &mLHS, Vector<> &vInputOutput)
{
  int nSize = mLHS.num_rows();
  int nInfo;
  assert(mLHS.num_cols() == nSize);
  assert(vInputOutput.size() == nSize);

  ::dpotrf_("U", &nSize, mLHS.get_data_ptr(), &nSize, &nInfo);
  if(nInfo!=0)
    return false;
  
  int nOne = 1;
  ::dpotrs_("U", &nSize, &nOne, mLHS.get_data_ptr(), &nSize, vInputOutput.get_data_ptr(), &nSize, &nInfo);
  if(nInfo!=0)
    return false;
  return true;
};


#endif
