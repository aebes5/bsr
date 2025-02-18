!====================================================================
      Subroutine ZNO_0ee
!====================================================================
!     computes overlap integral between two determinants
!     Calls: Idet_fact, Incode_int, Iadd_zoef
!--------------------------------------------------------------------
      Use spin_orbitals,  only: kz1,kz2

      Implicit none
      Integer :: idf,int
      Real(8) :: C
      Integer, external :: Idet_fact, Incode_int

      C = (-1)**(kz1+kz2)
      idf = Idet_fact (0,0,0,0)
      if(idf.lt.0) Return
      int = Incode_int (11,0,1,1,1,1)

      Call Iadd_zoef (C,int,idf)

      End Subroutine ZNO_0ee
