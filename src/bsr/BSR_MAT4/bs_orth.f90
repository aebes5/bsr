!=====================================================================
      Subroutine BS_ORTH
!=====================================================================
!     Including the orthogonal conditions for scattering orbitals
!     by updating the interaction matrix according the procedure
!     suggested by M.Bentley J.Phys.B27 (1994) 637. 
!
!     Let i-th channel is supposed to be orthogonal to orbital p.
!     It can be achieved by following modification of Hamiltonian:
!
!                H -->  (1 - Bcc') H (1 - cc'B) 
!
!     where c - full solution vector with all zero elements except
!     the channel i is replaced on B-spline expansion of orbital p
!     primes denote the transportasion. 
!
!     It leads to transformation of separate blocks  H(i,j):
!
!     H(i,j) with j <> i -->  (1 - Bpp') H(i,j)    
!     H(j,i) with j <> i -->   H(i,j) (1 - pp'B)   
!     H(i,i) with j  = i -->  (1 - Bpp') H(i,j) (1 - pp'B)    
!     j also includes the block for interaction with perturbers
!---------------------------------------------------------------------
      Use bsr_mat
      
      Implicit none
      Character(400) :: line
      Integer :: i,j, ii,jj, ij, ich,jch, nort, iline
      Real(8) :: v(ns), y(ns,ns),xx(ns,ns),yy(ns,ns),zz(ns,ns)
      Integer, external :: IBORT

      if(pri.gt.0) write(pri,'(/a/)') 'Orthogonal conditions:'

      Do ich = 1,nch; if(my_channel(ich).le.0) Cycle; i = ipch(ich)

! ... do we have ort.conditions for this cannel:
 
       zz = 0.d0
       nort = 0
       write(line,'(a,a)') ELC(ich),' -> '; iline=11 
       Do j = 1,nbf
        if(iech(j).gt.0) Cycle
        if(lbs(i).ne.lbs(j)) Cycle        
        if(IBORT(max(i,j),min(i,j)).ne.0) Cycle
        nort = nort + 1 
        write(line(iline:),'(a5)') EBS(j); iline=iline+5
        if(iline.gt.275) then
         if(pri.gt.0) write(pri,'(a)') trim(line); iline=11
        end if
        v = pbs(:,j)
        Do ii=1,ns; Do jj=1,ns
         zz(ii,jj) = zz(ii,jj) + v(ii)*v(jj)
        End do; End do        

       End do
       if(nort.eq.0) Cycle
       if(iline.gt.11.and.pri.gt.0) write(pri,'(a)') trim(line)

! ...  channel - channel block

       x = matmul (bb,zz)
       y = matmul (zz,bb)

       Do jch = 1,nch
        if(my_channel(jch).le.0) Cycle
        if(imycase(ich,jch)+imycase(jch,ich).eq.0) Cycle
        if(ich.gt.jch) then
         ij=imycase(ich,jch)
         xx = matmul (x,hcc(:,:,ij))
         hcc(:,:,ij) = hcc(:,:,ij) - xx
        elseif(ich.eq.jch) then
         ij=imycase(ich,jch)
         xx = matmul (x,hcc(:,:,ij))
         hcc(:,:,ij) = hcc(:,:,ij) - xx
         yy = matmul (hcc(:,:,ij),y)
         hcc(:,:,ij) = hcc(:,:,ij) - yy
        else
         ij=imycase(jch,ich)
         yy = matmul (hcc(:,:,ij),y)
         hcc(:,:,ij) = hcc(:,:,ij) - yy
        end if
       End do

! ...  channel - pertuber block

       if(npert.gt.0) then
        Do i = 1,npert
         if(my_channel(nch+i).le.0) Cycle
         j = icb(ich,i); if(j.eq.0) Cycle 
         hcb(:,j)=hcb(:,j)-matmul(hcb(:,j),y)
        End do
       end if
       
      End do ! over channels (ich)

      End Subroutine BS_ORTH

