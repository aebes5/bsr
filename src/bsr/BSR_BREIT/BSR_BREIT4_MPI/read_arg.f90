!======================================================================
      Subroutine Read_arg 
!======================================================================
!     read arguments from command line and check default settings
!======================================================================
      Use bsr_breit

      Implicit none

      Character(7) :: oper='1110000'	

! ... read arguments in command line:

      Call Read_iarg('klsp'  ,klsp  )
      Call Read_iarg('klsp1' ,klsp1 )
      Call Read_iarg('klsp2' ,klsp2 )
      Call Read_aarg('oper'  ,oper  )
      Call Read_iarg('mk'    ,mk    )
      Call Read_iarg('mkdt'  ,mkdt  )
      Call Read_iarg('mkt'   ,mkt   )
      Call Read_iarg('debug' ,debug )
      Call Read_rarg('time'  ,time_limit)

      Call Read_rarg('eps_c' ,eps_c)
      Call Read_rarg('eps_soo',eps_soo)

      if(klsp.ne.0) klsp1=klsp
      if(klsp2.lt.klsp1) klsp2=klsp1 

! ... define the operators under consideration:

      read(oper,'(7i1)') ioper

      write(pri,'(/a/)') 'Operators included: '

      if(ioper(1).gt.0) write(pri,'(a)') ' OVERLAPS'
      if(ioper(2).gt.0) write(pri,'(a)') ' KINATIC ENERGY'
      if(ioper(3).gt.0) write(pri,'(a)') ' TWO-ELECTRON ELECTROSTATIC'

      if(ioper(4).gt.0) write(pri,'(a)') ' SPIN ORBIT'
      if(ioper(5).gt.0) write(pri,'(a)') ' SPIN-OTHER-ORBIT'
      if(ioper(6).gt.0) write(pri,'(a)') ' SPIN-SPIN'
      if(ioper(7).gt.0) write(pri,'(a)') ' ORBIT-ORBIT'

      write(pri,'(/a,i3)') 'Max.multipole index =',mk
      write(pri,'(/a,E10.1/)') 'Tollerance for coeff.s =',eps_c

      End Subroutine Read_arg
