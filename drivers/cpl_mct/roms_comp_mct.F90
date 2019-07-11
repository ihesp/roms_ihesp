#define XROMS = 1

module roms_comp_mct

! !USES:
! #ifdef XROMS
!   use rxocn_comp_mct, only : roms_init_mct  => rxocn_init_mct, &
!                              roms_run_mct   => rxocn_run_mct,  &
!                              roms_final_mct => rxocn_final_mct
! #else
  use rocn_comp_mct, only : roms_init_mct  => rocn_init_mct, &
                            roms_run_mct   => rocn_run_mct,  &
                            roms_final_mct => rocn_final_mct
! #endif

!--------------------------------------------------------------------------
! Public interfaces
!--------------------------------------------------------------------------

  public :: roms_init_mct
  public :: roms_run_mct
  public :: roms_final_mct

end module roms_comp_mct
