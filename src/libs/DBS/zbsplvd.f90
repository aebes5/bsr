!=======================================================================
   SUBROUTINE zbsplvd(ns,ks,nv, t, kg, ni, x, nderiv, dbiatx)
!=======================================================================
!
!  This routine calculates the values of the B-splines and their deriva-
!  tives, of order up to nderiv, that do not vanish at x(i), i=1,..ni
!  There are ks such B-splines at each point.
!
!  This routine is a vector version of bsplvd written by C. de Boor,
!  ``A Practical Guide to Splines".
!
!  subroutine contained: vbsplvb
!
!-----------------------------------------------------------------------
!  on entry
!  --------
!  t     the knot array, of length nt >=nv+2ks-1.  It is assumed
!        that t(i) < t(i+1) for each interval containing an x(i)
!        Division by zero will result otherwise (in vbsplvb).
!
!  kg    gives the beginning interval from which the B-splines are
!        evaluated at the Gaussian points.
!
!  ni    the number of intervals in which B-splines are to be evaluated
!        at all Gaussian points, its uplimit is nt.
!
!  x     the point array at which these values are sought,
!        one per interval, of length ni.
!
!  nderiv   an integer indicating that values of B-splines and their
!        derivatives up to but not including the  nderiv-th  are asked
!        for.
!
!  working area
!  ------------
!  w31   a three dimensional array, w31(i,j,m) (j=1,..,ks m=1,..,ks) con-
!        tains B-coeff.s of the derivatives of a certain order of the
!        ks B-splines of interest at point x(i)
!
!  w1,w2      one dimensional arrays
!
!  on return
!  ---------
!  dbiatx     a three dimensional array. its entry (i,j,m) contains
!        value of  (m-1)st  derivative of  (l-ks+j)-th B-spline of
!        order ks at point x(i) for knot sequence t, i=1..ni,
!        j=m..ks; m=1..nderiv;and l=kg..kg+ni-1
!
!  method
!  ------
!  values at x(i) of all the relevant B-splines of order ks,ks-1,...,
!  ks+1-nderiv  are generated via vbsplvb and stored temporarily
!  in dbiatx. then, the B-coeffs of the required derivatives of the
!  B-splines of interest are generated by differencing, each from the
!  preceding one of lower order, and combined with the values of B-
!  splines of corresponding order in dbiatx to produce the desired
!  values.
!----------------------------------------------------------------------
    Implicit none
    Integer, intent(in) :: ns,ks,nv, kg, ni, nderiv
    Real(8), intent(in) :: t(ns+ks)
    Real(8), intent(inout):: dbiatx(nv,ks,ks)
    Real(8), intent(in):: x(ni)
    ! local variables
    Real(8) :: fkpimm
    Real(8) :: w1(ni),w2(ni)
    Real(8) :: w31(ni,ks,ks)
    Real(8) :: deltar(ni,ks), deltal(ni,ks)
    Integer :: i, j, n, m, mhigh, kp1, jhigh, ideriv, &
               ldummy, kpimm, jlow, jpimid, il

    mhigh = MAX(MIN(nderiv,ks),1)   !mhigh is usually equal to nderiv.
    kp1 = ks+1
    jhigh = kp1-mhigh
    Call zbsplvb(kg,ni,x,jhigh,1,dbiatx)
    IF(mhigh == 1) Return

    ! ..the first row of dbiatx always contains the B-spline values
    ! ..for the current order. these are stored in row ks+1-current
    ! ..order before vbsplvb is called to put values for the next
    ! ..higher order on top of it. Vbsplvb only uses the first two dimensions

    ideriv = mhigh
    Do m = 2, mhigh
      jpimid = 1
      Do j = ideriv,ks
       dbiatx(1:ni,j,ideriv) = dbiatx(1:ni,jpimid,1)
       jpimid = jpimid+1
      End do
      ideriv = ideriv-1
      jhigh = kp1-ideriv
      Call zbsplvb(kg,ni,x,jhigh,2,dbiatx)
    End do

    ! at this point,  b(.,n-ks+i, ks+1-j)(x) is in dbiatx(.,i,j) for
    ! n=kg..kg+ni-1,i=j..ks,j=1..mhigh('='nderiv).in particular,the
    ! first row of  dbiatx  is already in final form. to obtain cor-
    ! responding derivatives of B-splines in subsequent rows, gene-
    ! rate their B-repr. by differencing, then evaluate at x(.).

    jlow = 1
    Do i = 1,ks
      w31(1:ni,jlow:ks,i) = 0.d0
      jlow = i
      w31(1:ni,i,i) = 1.d0
    End do

    ! at this point, w31(.,.,j) contains the B-coeffs for the j-th of the
    ! ks B-splines of interest here.

    Do m = 2,mhigh
      kpimm = kp1-m
      fkpimm = kpimm
      i = ks
      il = 0

      ! for j=1,...,ks, construct B-coeffs of  (m-1)st  derivative of
      ! B-splines from those for preceding derivative by differencing
      ! and store again in  w31(.,.,j). the fact that w31(i,j) = 0  for
      ! i < j is used.

      Do ldummy = 1, kpimm
       Do n = kg-il,ni+kg-il-1
        w1(n-kg+il+1) = fkpimm/(t(n+kpimm)-t(n))
       End do

        ! the assumption that t(n) < t(n+1) makes denominator
        ! in w1(1..ni) nonzero.

        Do j = 1,i
         w31(1:ni,i,j) = (w31(1:ni,i,j)-w31(1:ni,i-1,j))*w1(1:ni)
        End do
        il = il+1
        i = i-1
      End do

      ! for i=1,...,ks, combine B-coeffs a(.,.,i) with B-spline values
      ! stored in dbiatx(.,.,m) to get value of (m-1)st  derivative of
      ! i-th B-spline (of interest here) at x(.), and store in
      ! dbiatx(.,i,m). storage of this value over the value of a B-spline
      ! of order m there is safe since the remaining B-spline derivat-
      ! ive of the same order do not use this value due to the fact
      ! that  a(.,j,i) = 0  for j .lt. i .

      Do i = 1,ks
        w2(1:ni) = 0.d0
        jlow = MAX(i,m)
        Do j = jlow,ks
          w2(1:ni) = w2(1:ni) + w31(1:ni,j,i)*dbiatx(1:ni,j,m)
        End do
        dbiatx(1:ni,i,m) = w2(1:ni)
      End do

    End do

CONTAINS


!===================================================================
   Subroutine zbsplvb(kg, ni, x, jhigh, index, biatx)
!=====================================================================
!  This routine calculates the values of all possibly nonzero B-splines
!  at x(i) (i=1,..ni) of order
!               jout=max(jhigh,(j+1)*(index-1))
!  with knot sequence t.
!
!  This routine is a vector version of bsplvb written by C. de Boor,
!  "A Practical Guide to Splines", Chapter X, page 135
!
!  on entry
!  --------
!  t    -  knot sequence, of length nt=ns+ks, assumed to be nonde-
!          creasing, that is t(i) <= t(i+1)
!
!  jhigh-  choose jhigh=1 to get the B-spline values directly
!            by calling vbsplvb.
!
!  kg   -  gives the beginning interval from which the B-splines
!           are to be evaluated at Gaussin points.
!
!  ni   -  the number of intervals in which B-splines are
!            evaluated at all Gaussian points, its uplimit is nv.
!
!  x    -  the points at which the B-splines are to be evaluated,
!            its length is ni,
!
!  index-  integers which determine the order  jout = max(jhigh,
!            (j+1)*(index-1))  of the B-splines whose values at x(i)
!            are to be returned.  index is used to avoid recalcula-
!            tions when several columns of the triangular array of
!            B-spline values are needed (e.g., in vbsplvd ).
!            More precisely,
!                     if index = 1 ,
!            the calculation starts from scratch and the entire
!            triangular array of B-spline values of orders
!            1,2,...,jhigh is generated, order by order ,
!            i.e., column by column .
!                     if  index = 2 ,
!            only the B-spline values of order  j+1, j+2, ..., jout
!            are generated, the assumption being that  biatx,j,
!            deltal,deltar are, on  entry, as they were on exit at the
!            previous call. In particular, if  jhigh = 0, then
!            jout = j+1, i.e., just the next column of B-spline
!            values is generated.
!
!  working area
!  ------------
!  deltal, deltar: two dimensional arrays
!  term, saved:    one dimensional arrays.
!
!  on return
!  ---------
!  biatx.....two dimensional array, with biatx(j-k+1,i)(j=k..ni)
!        containing the value at x(j-k+1) of the polynomial of order
!        jout which agrees with the B-spline b(j-jout+1,jout,t) on
!        the interval (t(j),t(j+1)).
!
!  method
!  ------
!  The recurrence relation
!
!                       x - t(i)              t(i+j+1) - x
!     b(i,j+1)(x)  =  -----------b(i,j)(x) + ---------------b(i+1,j)(x)
!                     t(i+j)-t(i)            t(i+j+1)-t(i+1)
!
!  is used (repeatedly) to generate the (j+1)-vector  b(l-j,j+1)(x),
!  ...,b(l,j+1)(x)  from the j-vector  b(l-j+1,j)(x),...,
!  b(l,j)(x), storing the new values in  biatx  over the old. the
!  facts that
!            b(i,1) = 1  if  t(i) <= x < t(i+1)
!  and that
!            b(i,j)(x) = 0  unless  t(i) <= x < t(i+j)
!  are used. the particular organization of the calculations follows al-
!  gorithm (8) in chapter x of the text.
!-----------------------------------------------------------------------
    Implicit none
    Integer, intent(in):: kg, ni, jhigh, index
    Real(8), intent(in):: x(ni)
    Real(8), intent(inout):: biatx(nv,ks)
    ! .. Local variables
    Integer :: i, jp1, m
    Integer, save :: j=1
    Real(8) :: term(ni), saved(ni)

    if(index == 1) then
      j=1
      biatx(1:ni,1)=1.d0
      IF (j >= jhigh)  Return
    end if

    Do
      jp1=j+1
      saved(1:ni)=0.d0
      Do i=1,ni
        deltar(i,j) = t(i+kg-1+j) - x(i)
        deltal(i,j) = x(i) - t(i+kg-j)
      End do

      Do m=1,j
        Do i=1,ni
          term(i)=biatx(i,m)/(deltar(i,m)+deltal(i,jp1-m))
          biatx(i,m)=saved(i)+deltar(i,m)*term(i)
          saved(i)=deltal(i,jp1-m)*term(i)
        End do
      End do

      biatx(1:ni,jp1)=saved(1:ni)
      j=jp1
      if (j >= jhigh) Exit
    End do
    End Subroutine zbsplvb

    End Subroutine zbsplvd
