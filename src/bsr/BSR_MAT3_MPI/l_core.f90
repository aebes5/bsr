!======================================================================
      Module L_core
!======================================================================
!
!     contain B-spline representation for L-integral
!     including the interaction with core
!
!----------------------------------------------------------------------
!
!     hl(ns,ks) - matrix of Z-operator in the B-splne basis
!                 (in symmetric lower-column mode)
!
!     hl_dir(ns,ks) - direct interaction with core
!                     (in symmetric upper-column mode)
!
!     hl and hl_dir have different representation !!!
!
!     hl_dir = [-1|1] - (not|yes) for done of zl_dir
!     this parameter allows us to compute the zl_dir only once 
!
!     hl and hl_dir does not depend on l (can be calculated only once) 
!
!     hl_exc(ns,ns) - exchange interaction with core
!
!     hl_core(ns,ns) - final zl with core interaction
!                      (in full representation)
!
!     mlz - max. l for so-interaction
!
!     hl_full(ns,ns,mlz) - all L-matreces
!
!     vc(ns,ks)  - rel.correction
!
!------------------------------------------------------------------

      Implicit none
    
      Integer :: lh_dir, mlh
    
      Real(8), Allocatable :: hl(:,:),hl_dir(:,:),hl_exc(:,:),hl_core(:,:)

      Real(8), Allocatable :: vc(:,:)

      Real(8), Allocatable :: hl_full(:,:,:)

! ... L-integrals, <P_i| L |P_j>, and vectors  < . | L | P_i>:

      Real(8), Allocatable :: L_int(:,:), L_vec(:,:)

! ... exiliary arrays:

      Real(8), Allocatable :: x(:,:),xx(:,:)

      End MODULE L_core



!=====================================================================
      Subroutine Alloc_Lcore(ns,ks,nbf)
!=====================================================================
!     allocation arrays in L_core module
!---------------------------------------------------------------------
      Use L_core
      Implicit none
      Integer, intent(in) :: ns,ks,nbf
      Integer :: info

      if(ns.gt.0) then

       if(Allocated(hl)) Return

       Allocate(hl(ns,ks), hl_dir(ns,ks), &
                hl_exc(ns,ns), hl_core(ns,ns), &
                x(ns,ks),xx(ns,ns),vc(ns,ks), STAT=info)
       if(info.ne.0) then
         write(*,*) 'hl,info =',ns,ks,info 
         Stop 'hl'
       end if

       Allocate(L_int(nbf,nbf),Stat=info)

       if(info.ne.0) then
         write(*,*) 'L_int,info =',nbf,info 
         Stop 'L_int'
       end if

       Allocate(L_vec(ns,nbf), STAT=info)
       if(info.ne.0) then
        write(*,*) 'L_vec,ibfo =',nbf,info 
        Stop 'L_vec'
       end if

       Allocate(hl_full(ns,ns,0:mlh), STAT=info)
       if(info.ne.0) then
        write(*,*) 'hl_full,info =',mlh,info 
        Stop 'hl_full'
       end if

       x=0.d0; xx=0.d0
       L_int = 0.d0; L_vec = 0.d0
       lh_dir = -1

      else

       if(.not.Allocated(hl)) Return

       Deallocate(hl,hl_dir,hl_exc,hl_core,hl_full, &
                  L_int,L_vec, x,xx, vc)
       lh_dir = -1

      end if

      End Subroutine Alloc_Lcore



!======================================================================
      SUBROUTINE Gen_Lval
!======================================================================
!     Generates the L-integrals <i|L|j> and vectors <.|L|j> 
!----------------------------------------------------------------------
      Use spline_param; USE spline_atomic; Use spline_orbitals
      Use L_core; Use bsr_mat

      Implicit none
      Integer :: i,j,k,l,m, ii,jj
      Real(8) :: C, S
      Integer, External :: ipointer
      Real(8), External :: BVMV

! ... find max. l :      

      mlh=0; Do i=1,nbf; if(lbs(i).gt.mlh) mlh=lbs(i); End do 

      Call Alloc_Lcore(ns,ks,nbf)

! ... generate L-data for given l: 

      Do l=0,mlh

       if(ipointer(nbf,lbs,l).eq.0) Cycle 

       Call INT_core(l)               

       Do i = kclosd+1,nbf;  if(lbs(i).ne.l.or.iech(i).ne.0) Cycle 
        Do j = i,nbf;        if(lbs(j).ne.l.or.iech(j).ne.0) Cycle 

         C = 0.d0 
         do m = 1,ns
          do k = 1,m-1
           C = C + hl_core(m,k)*(pbs(m,i)*pbs(k,j)+pbs(k,i)*pbs(m,j))
          end do
         end do
         do m = 1,ns
          C = C + hl_core(m,m)*pbs(m,i)*pbs(m,j)
         end do

! ... rel. correction to L(i,j):

         k=0
         if(rel.and.imvc.lt.0) k=1
         if(nmvc.gt.0.and.nbs(i).gt.nmvc.and.nbs(j).gt.nmvc) k=0 
         if(k.gt.0)  then 
           S = BVMV(ns,ks,vc,'s',pbs(1,i),pbs(1,j)) 
           C = C + S 
         end if

         L_int(i,j) = C;  L_int(j,i) = C
 
         if(nud.gt.0) Call pri_int(nud,6,0,i,j,i,j,C)

        End do

        Do m=1,ns; L_vec(m,i)=SUM(hl_core(:,m)*pbs(:,i)); End do
 
! ... rel. correction to vector L(.,i):

        k=0
        if(rel.and.imvc.eq.-1) k=1
        if(nmvc.gt.0.and.nbs(i).gt.nmvc) k=0 
        if(k.gt.0) then
         L_vec(1:ns,i) = L_vec(1:ns,i) + vc(1:ns,ks)*pbs(1:ns,i)
         Do m = 1,ks-1
          Do ii = ks-m+1,ns
           jj = ii-ks+m
           L_vec(ii,i) = L_vec(ii,i) + vc(ii,m)*pbs(jj,i)     
           L_vec(jj,i) = L_vec(jj,i) + vc(ii,m)*pbs(ii,i)     
          End do
         End do
        end if

       End do

       hl_full(:,:,l) = hl_core(:,:)               

      End do 

      End SUBROUTINE Gen_Lval




!=====================================================================
      Subroutine INT_core(l)
!=====================================================================
!     generate B-spline representation for interaction with core
!---------------------------------------------------------------------

      USE spline_param;  USE spline_atomic;  USE spline_orbitals
      USE spline_grid; Use spline_galerkin

      USE L_core; Use bsr_mat

      Implicit none
      
      Integer, Intent(in) :: l

      Integer :: i,j, ip,jp, k,kmin,kmax

      Real(8) :: C1, C2
      Character(1) :: sym

      Real(8), External :: ZCB

!...  set up hl matrix ...

      C1=l*(l+1); C2=2*z; hl=db2-C1*rm2+C2*rm1

! ... symmetrize hl by Bloch operator on right boder 

      C1 = db2(1,1)-db2(ns,ks-1)
      hl(ns,ks-1) = hl(ns,ks-1) + C1
      hl(ns,ks  ) = hl(ns,ks  ) - C1
      
! ... symmetrize hl by Bloch operator on left boder 

!      C2 = (ks-1)/(t(ks+1)-t(ks))         
!      hl(2,ks-1) = hl(2,ks-1) + C2 
!      hl(1,ks  ) = hl(1,ks)   - C2
     
! ... relativistic shift ...

      if(rel) then
       Call mvcv(l,vc); if(imvc.gt.0) hl=hl+vc
      end if

! ... interaction with core ...  

      hl_exc = 0.d0

      if(kclosd.gt.0) then
    
! ... direct interaction ...

      if(lh_dir.eq.-1) then
       Call MRK_cell(0)
       hl_dir = 0.0d0
       Do ip = 1,kclosd
        C1 = -2.d0*(4*lbs(ip)+2)
        Call INT_de(pbs(1,ip),pbs(1,ip),x,5,2,sym)
        hl_dir = hl_dir + C1 * x
       End do
       lh_dir = 1
      end if

! ... exchange interaction ...
      
      kmin = 1000; kmax = 0
      Do ip = 1,kclosd
       k = iabs(l-lbs(ip));  if(kmin.gt.k) kmin=k
       k =      l+lbs(ip) ;  if(kmax.lt.k) kmax=k
      End do

      Do k = kmin, kmax
       Call MRK_cell(k)
       Do ip = 1,kclosd
        C1 = (4*lbs(ip)+2) * ZCB(l,k,lbs(ip))
        if(C1.eq.0.d0) Cycle
        Call INT_de (pbs(1,ip),pbs(1,ip),xx,5,3,sym)       
        hl_exc(:,:) = hl_exc(:,:) + C1*xx
       End do
      End do    

      end if ! kclose > 0

!----------------------------------------------------------------------
! ... total hl:      

      hl_core = hl_exc

      Do jp = 1,ks
       Do i = 1-jp+ks,ns
        j = i+jp-ks
        hl_core(i,j) = hl_core(i,j) + hl(i,jp)
        hl_core(j,i) = hl_core(i,j)
       End do
      End do

      if(kclosd.gt.0) then

      Do jp = 1,ks
       Do i = 1,ns-jp+1
        j = i+jp-1
        hl_core(i,j) = hl_core(i,j) + hl_dir(i,jp)
        hl_core(j,i) = hl_core(i,j)
       End do
      End do
     
      end if

      End Subroutine INT_core


!====================================================================
    SUBROUTINE mvcv(l,vc)
!====================================================================
!
!   Computes the matrix elements for the mass-velocity correction
!   in the B-spline basis.  The lack of symmetry in the d^2/dr^2
!   operator is ignored.
!
!     VC(i,j) = INT [  (d^2/dr^2 - l(l+1)/r) B_i(r) *
!                      (d^2/dr^2 - l(l+1)/r) B_j(r)  ] dr
!--------------------------------------------------------------------
!

!   on entry
!   --------
!       l    the angular momentum
!
!   on exit
!   -------
!       vc   the mass velocity correction in symmetric storage mode
!
!--------------------------------------------------------------------

    USE spline_param; USE spline_atomic;  USE spline_grid
    
    IMPLICIT NONE

    INTEGER, INTENT(in) :: l
    REAL(8), INTENT(inout), Dimension(ns,ks) :: vc

    INTEGER :: m, ith, jth, i, irow, jcol
    REAL(8) :: fll, y1, y2, S, B
    Real(8), External :: AZL

! .. initialize the vc array

    vc = 0.d0;  fll = l*(l+1);  nv = ns-ks+1

! .. compute the matrix elements

    do m = 1,ks
      do i = 1,nv
        S = fll*grm(i,m)*grm(i,m)

! ... cutoff correction

        B = gr(i,m)/(gr(i,m)+2*fine*Z);  B = B*B*B

        do ith = 1,ks
          irow = i+ith-1
          do jth = 1,ith
          jcol = jth-ith+ks

            y1 = bspd(i,m,ith,2) - S*bsp(i,m,ith)
            y2 = bspd(i,m,jth,2) - S*bsp(i,m,jth)
            vc(irow,jcol) = vc(irow,jcol) + grw(i,m)*y1*y2 !* B

          end do
        end do

      end do
    end do

    vc = vc * fine

! ... one-electron Darwin correction:

    if(l.eq.0) then
      S = azl(z,h,ks,l+1);  vc(2,ks) = vc(2,ks) - z*S*S*fine
    end if


    END SUBROUTINE mvcv


