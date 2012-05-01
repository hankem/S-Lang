\function{hist1d}
\synopsis{Compute a 1-d histogram}
\usage{h = hist1d ([h,] pnts, grid [, &rev])}
\description
 The \ifun{hist1d} function bins a set of points \exmp{pnts} into a
 1-d histogram using bin-edges given by the grid argument.  The
 optional last argument \exmp{&rev} is a reference to a variable
 whose value will be assigned the reverse-indices of the histogram.  
 
 The first argument \exmp{h} is optional.  If present and non-NULL, it
 will be used as the histogram buffer with new binned values added to
 it.  That is, the following statements are equivalent:
#v+
    h = h + hist1d (pnts, grid);
    h = hist1d (h, pnts, grid);
#v-

 The value of the ith bin in the histogram is given by the number of
 values in the \exmp{pnts} array that satisfy
 \exmp{grid[i]<=X<grid[i+1]} where \exmp{X} represents the value of
 the candidate point.  The last bin of the histogram represents an
 overflow bin with the right bin edge at plus infinity.  The grid is
 required to be sorted into ascending order.

 The reverse-indices array is an array-of-arrays of indices such that
 \exmp{rev[i]} is an array of indices into the \exmp{pnts} array that
 have fallen into the ith bin.
\seealso{hist1d_rebin, hist2d, hist2d_rebin, hist_bsearch}
\done

\function{hist2d}
\synopsis{Compute a 2-d histogram}
\usage{h = hist2d ([h,] xpnts, ypnts, xgrid, ygrid [, &rev])}
\description
 The \ifun{hist2d} function bins a set of \exmp{(x,y)} pairs
 represented by the \exmp{xpnts} and \exmp{ypnts} arrays into a 2-d
 histogram using bin-edges given by the \exmp{xgrid} and \exmp{ygrid}
 arguments.  The optional last argument \exmp{&rev} is a reference to
 a variable whose value will be assigned the reverse-indices of the
 histogram.  The first argument is also optional and, if present and
 non-NULL, will be used for the histogram values.

 The value of the bin \exmp{[i,j]} of the histogram is given by the
 number of (X,Y) pairs that satisfy \exmp{xgrid[i]<=X<xgrid[i+1]} and
 \exmp{ygrid[j]<=Y<ygrid[j+1]}. The bins at the extreme edges of the
 histogram represent overflow bins with the upper bin edge at plus
 infinity. The grids are required to be sorted into ascending order.

 The reverse-indices array is a 2-d array-of-arrays of indices such that
 \exmp{rev[i,j]} is an array of indices into the \exmp{xpnts} and
 \exmp{ypnts} arrays that have fallen into the bin \exmp{[i,j]}.

\seealso{hist1d, whist2d, hist2d_rebin, hist1d_rebin, hist_bsearch}
\done


\function{hist1d_rebin}
\synopsis{Rebin a 1-d histogram}
\usage{new_h = hist1d_rebin (new_grid, old_grid, old_h)}
\description
  The \ifun{hist1d_rebin} function rebins a histogram \exmp{old_h}
  with bin edges defined by \exmp{old_grid} into a histogram with bin
  edges given by \exmp{new_grid}.  The rebinning operation preserves
  the normalization of the histogram where the grids overlap.

  Unlike the \exmp{hist1d} function which returns an integer array,
  the \exmp{hist1d_rebin} function returns an array of doubles since
  the new grid does not have to be commensurate with the old grid.
\seealso{hist1d, hist2d_rebin, hist2d, hist_bsearch}
\done

\function{hist2d_rebin}
\synopsis{Rebin a 2-d histogram}
\usage{new_h = hist2d_rebin (new_xgrid, new_ygrid, old_xgrid, old_ygrid, old_h)}
\description
  The \ifun{hist2d_rebin} function rebins a 2-d histogram \exmp{old_h}
  with bin edges defined by \exmp{old_xgrid} and \exmp{old_ygrid} into
  a 2-d histogram with bin edges given by \exmp{new_xgrid} and
  \exmp{new_ygrid}.
  
  Unlike the \exmp{hist2d} function which returns an integer array,
  the \exmp{hist2d_rebin} function returns an array of doubles since
  the new grids do not have to be commensurate with the old grids.
\seealso{hist1d_rebin, hist2d, whist2d, hist_bsearch}
\done

\function{hist_bsearch}
\synopsis{Perform a binary search}
\usage{i = hist_bsearch (x, xbins)}
\description
  The \ifun{hist_bsearch} function performs a binary search for the
  bin \exmp{i} satisfying \exmp{xbins[i]<=x<xbins[i+1]}.  If the value
  \exmp{x} is greater than or equal to the value of the last bin, the
  index of the last bin will be returned.  If \var{x} is smaller than
  the value of the first bin (\exmp{xbins[0]}), then the function will
  return the index of the first bin, i.e., \exmp{0}. The grid is
  required to be sorted into ascending order.

  If the value of \exmp{x} is an array, an array of indices will be
  returned.
\notes
  As pointed out above, if the value of \exmp{x} is less than the value
  of the first bin, the index of the first bin will be returned even
  though \exmp{x} does not belong to the bin.  If this behavior is not
  desired, then such points should be filtered out before the binary
  search is performed.
\seealso{hist1d, hist1d_rebin}
\done


\function{whist1d}
\synopsis{Created a weighted 1-d histogram}
\usage{h = whist1d (pnts, wghts, grid [,&rev [,&weight_func]]}
\description
 The \ifun{whist1d} function creates a 1-dimensional weighted
 histogram.  The value of the ith bin in the histogram is given by a
 function applied to values of the \exmp{wghts} that correspond to
 those values in the \exmp{pnts} array that satisfy
 \exmp{grid[i]<=X<grid[i+1]} where \exmp{X} represents the value of
 the candidate point.  The last bin of the histogram represents an
 overflow bin with the right bin edge at plus infinity.  The grid is
 required to be sorted into ascending order.
 
 If the optional fourth argument \exmp{&rev} is present, upon return
 it will be set to the array of reverse-indices of the histogram.  The
 optional \exmp{&weight_func} argument may be used to specify the
 function to be applied to the weights array.  By default, the
 \ifun{sum} function will be used.
\notes
 The source code to this function may be found in \file{histogram.sl}.
 As such, it is available only after this file has been loaded.
 Simply importing the module will not load this function into the
 interpreter.
\seealso{hist1d, whist2d, hist1d_rebin}
\done

\function{whist2d}
\synopsis{Created a weighted 2-d histogram}
\usage{h = whist2d (xpnts, ypnts, wghts, xgrid, ygrid [,&rev [,&weight_func]]}
\description
 The \ifun{whist2d} function creates a 2-dimensional weighted
 histogram.  The value of the bin \exmp{[i,j]} of the histogram is
 given by a function applied to those values in the \exmp{wghts} array
 that correspond to the (X,Y) pairs that satisfy
 \exmp{xgrid[i]<=X<xgrid[i+1]} and \exmp{ygrid[i]<=Y<ygrid[i+1]}.  The
 bins at the extreme edges of the histogram represent overflow bins
 with the upper bin edge at plus infinity. The grids are required to
 be sorted into ascending order.
 
 If the optional sixth argument \exmp{&rev} is present, upon return
 it will be set to the array of reverse-indices of the histogram.  The
 optional \exmp{&weight_func} argument may be used to specify the
 function to be applied to the weights array.  By default, the
 \ifun{sum} function will be used.
\notes
 The source code to this function may be found in \file{histogram.sl}.
 As such, it is available only after this file has been loaded.
 Simply importing the module will not load this function into the
 interpreter.
\seealso{hist2d, whist1d, hist1d, hist2d_rebin}
\done

