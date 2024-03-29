#include "cppdefs.h"
#if defined ADJOINT && defined SOLVE3D
      SUBROUTINE ad_main3d (RunInterval)
!
!svn $Id: ad_main3d.F 561 2011-05-05 21:12:40Z arango $
!================================================== Hernan G. Arango ===
!  Copyright (c) 2002-2011 The ROMS/TOMS Group       Andrew M. Moore   !
!    Licensed under a MIT/X style license                              !
!    See License_ROMS.txt                                              !
!=======================================================================
!                                                                      !
!  This subroutine is the main driver for adjoint  ROMS/TOMS when      !
!  configurated as a full 3D baroclinic  ocean model. It advances      !
!  backwards the adjoint model equations for all nested grids, if      !
!  any, by the specified time interval (seconds), RunInterval.         !
!                                                                      !
!=======================================================================
!
      USE mod_param
      USE mod_parallel
# ifdef MODEL_COUPLING
      USE mod_coupler
# endif
# ifdef FOUR_DVAR
      USE mod_fourdvar
# endif
      USE mod_iounits
      USE mod_scalars
      USE mod_stepping
# ifdef SO_SEMI
      USE mod_storage
# endif
!
# if defined AD_SENSITIVITY   || defined IS4DVAR_SENSITIVITY || \
     defined OPT_OBSERVATIONS || defined SENSITIVITY_4DVAR
      USE adsen_force_mod, ONLY : adsen_force
# endif
# ifdef ANA_VMIX
      USE analytical_mod, ONLY : ana_vmix
# endif
# ifdef BIOLOGY
      USE ad_biology_mod, ONLY : ad_biology
# endif
# ifdef BBL_MODEL_NOT_YET
!!    USE ad_bbl_mod, ONLY : ad_bblm
# endif
# if defined BULK_FLUXES_NOT_YET && !defined NL_BULK_FLUXES
!!    USE ad_bulk_flux_mod, ONLY : ad_bulk_flux
# endif
# ifdef BVF_MIXING_NOT_YET
!!    USE ad_bvf_mix_mod, ONLY : ad_bvf_mix
# endif
      USE ad_diag_mod, ONLY : ad_diag
# if defined ADJUST_STFLUX || defined ADJUST_WSTRESS
      USE ad_frc_adjust_mod, ONLY : ad_frc_adjust
# endif
      USE ad_ini_fields_mod, ONLY : ad_ini_fields, ad_ini_zeta
# ifdef WEAK_CONSTRAINT
      USE ad_forcing_mod, ONLY : ad_forcing
# endif
# ifdef GLS_MIXING_NOT_YET
!!    USE ad_gls_corstep_mod, ONLY : ad_gls_corstep
!!    USE ad_gls_prestep_mod, ONLY : ad_gls_prestep
# endif
# ifdef LMD_MIXING_NOT_YET
!!    USE ad_lmd_vmix_mod, ONLY : ad_lmd_vmix
# endif
# if defined FOUR_DVAR && defined OBSERVATIONS
#  ifdef WEAK_CONSTRAINT
      USE ad_htobs_mod, ONLY : ad_htobs
#  else
      USE ad_misfit_mod, ONLY : ad_misfit
#  endif
# endif
# ifdef MY25_MIXING
!!    USE ad_my25_corstep_mod, ONLY : ad_my25_corstep
!!    USE ad_my25_prestep_mod, ONLY : ad_my25_prestep
# endif
# ifdef ADJUST_BOUNDARY
      USE ad_obc_adjust_mod, ONLY : ad_obc_adjust
      USE ad_obc_adjust_mod, ONLY : ad_obc2d_adjust
      USE ad_set_depth_mod, ONLY : ad_set_depth_bry
# endif
      USE ad_omega_mod, ONLY : ad_omega
# ifdef NEARSHORE_MELLOR_NOT_YET
!!    USE ad_radiation_stress_mod, ONLY : ad_radiation_stress
# endif
# ifndef TS_FIXED
      USE ad_rho_eos_mod, ONLY : ad_rho_eos
# endif
      USE ad_rhs3d_mod, ONLY : ad_rhs3d
# ifdef SEDIMENT_NOT_YET
!!    USE ad_sediment_mod, ONLY : ad_sediment
# endif
# ifdef AD_AVERAGES
      USE ad_set_avg_mod, ONLY : ad_set_avg
# endif
      USE ad_set_depth_mod, ONLY : ad_set_depth
      USE ad_set_massflux_mod, ONLY : ad_set_massflux
# if defined SSH_TIDES_NOT_YET || defined UV_TIDES_NOT_YET
!!    USE ad_set_tides_mod, ONLY : ad_set_tides
# endif
      USE ad_set_vbc_mod, ONLY : ad_set_vbc
      USE ad_set_zeta_mod, ONLY : ad_set_zeta
      USE ad_step2d_mod, ONLY : ad_step2d
# ifndef TS_FIXED
      USE ad_step3d_t_mod, ONLY : ad_step3d_t
# endif
      USE ad_step3d_uv_mod, ONLY : ad_step3d_uv
# ifdef FLOATS_NOT_YET
!!    USE ad_step_floats_mod, ONLY : ad_step_floats
# endif
# if defined BULK_FLUXES && !defined NL_BULK_FLUXES
      USE bulk_flux_mod, ONLY : bulk_flux
# endif
# ifdef AIR_OCEAN_NOT_YET
      USE ocean_coupler_mod, ONLY : atmos_coupling
# endif
# ifdef WEAK_CONSTRAINT
      USE frc_weak_mod, ONLY : frc_ADgather, frc_clear
# endif
# ifdef WAVES_OCEAN_NOT_YET
      USE ocean_coupler_mod, ONLY : waves_coupling
# endif
      USE omega_mod, ONLY : omega
# ifdef SO_SEMI
      USE packing_mod, ONLY : ad_pack
# endif
      USE rho_eos_mod, ONLY : rho_eos
      USE set_depth_mod, ONLY : set_depth
      USE set_massflux_mod
!!    USE wvelocity_mod, ONLY : wvelocity
!
      implicit none
!
!  Imported variable declarations.
!
      real(r8), intent(in) :: RunInterval
!
!  Local variable declarations.
!
      logical :: backward = .TRUE.

      integer :: my_iif, ng, next_indx1, subs, tile, thread
# ifdef FLOATS_NOT_YET
      integer :: Lend, Lstr, chunk_size
# endif
      integer :: ks, kt

      real(r8) :: HalfDT, my_StepTime
!
!=======================================================================
!  Time-step adjoint 3D primitive equations backwards.
!=======================================================================
!
      my_StepTime=0.0_r8

      STEP_LOOP : DO WHILE (my_StepTime.le.RunInterval)

        my_StepTime=my_StepTime+MAXVAL(dt)
!
!  Set time clock.
!
        DO ng=1,Ngrids
          iic(ng)=iic(ng)-1
          time(ng)=time(ng)-dt(ng)
          tdays(ng)=time(ng)*sec2day
          CALL time_string (time(ng), time_code(ng))
        END DO
!
!-----------------------------------------------------------------------
!  Read in required data, if any, from input NetCDF files.
!-----------------------------------------------------------------------
!
        DO ng=1,Ngrids
          CALL ad_get_data (ng)
          IF (exit_flag.ne.NoError) RETURN
        END DO
!
!-----------------------------------------------------------------------
!  Process input data, if any: time interpolate between snapshots.
!-----------------------------------------------------------------------
!
        DO ng=1,Ngrids
!$OMP PARALLEL DO PRIVATE(thread,subs,tile) SHARED(numthreads)
          DO thread=0,numthreads-1
            subs=NtileX(ng)*NtileE(ng)/numthreads
            DO tile=subs*thread,subs*(thread+1)-1,+1
              CALL ad_set_data (ng, TILE)
# ifdef FORWARD_READ
              CALL set_depth (ng, TILE)
# endif
            END DO
          END DO
!$OMP END PARALLEL DO
        END DO
        IF (exit_flag.ne.NoError) RETURN

# ifdef FORWARD_READ
!
!-----------------------------------------------------------------------
!  Compute BASIC STATE horizontal mass fluxes (Hz*u/n and Hz*v/m).
!-----------------------------------------------------------------------
!
        DO ng=1,Ngrids
!$OMP PARALLEL DO PRIVATE(thread,subs,tile) SHARED(numthreads)
          DO thread=0,numthreads-1
            subs=NtileX(ng)*NtileE(ng)/numthreads
            DO tile=subs*(thread+1)-1,subs*thread,-1
              CALL set_massflux (ng, TILE)
              CALL rho_eos (ng, TILE)
#  if defined BULK_FLUXES && !defined NL_BULK_FLUXES
              CALL bulk_flux (ng, TILE)
#  endif
            END DO
          END DO
!$OMP END PARALLEL DO
        END DO
# endif
!
!  Avoid time-stepping if additional delayed IO time-step.
!
        TIME_STEP : IF (MINVAL(iic).ne.MINVAL(ntstart)) THEN

# ifdef FLOATS_NOT_YET
!
!-----------------------------------------------------------------------
!  Compute Lagrangian drifters trajectories.
!-----------------------------------------------------------------------
!
!  Shift floats time indices.
!
          DO ng=1,Ngrids
            IF (Lfloats(Ng)) THEN
              nfp1(ng)=MOD(nfp1(ng)+1,NFT+1)
              nf  (ng)=MOD(nf  (ng)+1,NFT+1)
              nfm1(ng)=MOD(nfm1(ng)+1,NFT+1)
              nfm2(ng)=MOD(nfm2(ng)+1,NFT+1)
              nfm3(ng)=MOD(nfm3(ng)+1,NFT+1)
!
!$OMP PARALLEL DO PRIVATE(thread,chunk_size,Lstr,Lend)                  &
!$OMP&            SHARED(numthreads,Nfloats)
              DO thread=0,numthreads-1
                chunk_size=(Nfloats(ng)+numthreads-1)/numthreads
                Lstr=1+thread*chunk_size
                Lend=MIN(Nfloats(ng),Lstr+chunk_size-1)
                CALL ad_step_floats (ng, Lstr, Lend)
              END DO
!$OMP END PARALLEL DO
            END IF
          END DO
# endif

# ifndef TS_FIXED
!
!-----------------------------------------------------------------------
!  Time-step adjoint tracer equations.
!-----------------------------------------------------------------------
!
!  Compute intermediate BASIC STATE mass fluxes (Huon,Hvom) for use in
!  the adjoint horizontal advection (ad_step3d_t) and adjoint vertical
!  velocity (ad_omega).
!
          DO ng=1,Ngrids
!$OMP PARALLEL DO PRIVATE(thread,subs,tile) SHARED(numthreads)
            DO thread=0,numthreads-1
              subs=NtileX(ng)*NtileE(ng)/numthreads
              DO tile=subs*thread,subs*(thread+1)-1,+1
                CALL reset_massflux (ng, TILE)     ! intermediate fluxes
              END DO
            END DO
!$OMP END PARALLEL DO
          END DO
!
!  Compute basic STATE omega vertical velocity with intermediate mass
!  fluxes. Time-step adjoint tracer equations.
!
          DO ng=1,Ngrids
!$OMP PARALLEL DO PRIVATE(thread,subs,tile) SHARED(numthreads)
            DO thread=0,numthreads-1
              subs=NtileX(ng)*NtileE(ng)/numthreads
              DO tile=subs*(thread+1)-1,subs*thread,-1
                CALL omega (ng, TILE)           ! BASIC STATE w-velocity
                CALL ad_step3d_t (ng, TILE)
              END DO
            END DO
!$OMP END PARALLEL DO
          END DO
# endif
!
!-----------------------------------------------------------------------
!  Time-step adjoint vertical mixing turbulent equations and passive
!  tracer source and sink terms, if applicable. Reinstate original
!  BASIC STATE (Huon,Hvom).
!-----------------------------------------------------------------------
!
          DO ng=1,Ngrids
!$OMP PARALLEL DO PRIVATE(thread,subs,tile) SHARED(numthreads)
            DO thread=0,numthreads-1
              subs=NtileX(ng)*NtileE(ng)/numthreads
              DO tile=subs*thread,subs*(thread+1)-1,+1
# ifdef SEDIMENT_NOT_YET
                CALL ad_sediment (ng, TILE)
# endif
# ifdef BIOLOGY
                CALL ad_biology (ng, TILE)
# endif
# ifdef MY25_MIXING_NOT_YET
                CALL ad_my25_corstep (ng, TILE)
# elif defined GLS_MIXING_NOT_YET
                CALL ad_gls_corstep (ng, TILE)
# endif
                CALL ad_omega (ng, TILE)
                CALL set_massflux (ng, TILE)   ! BASIC STATE mass fluxes
              END DO
            END DO
!$OMP END PARALLEL DO
          END DO
!
!-----------------------------------------------------------------------
!  Time-step adjoint 3D equations.
!-----------------------------------------------------------------------
!
!  Reinstate original BASIC STATE omega vertical velocity. Time-step
!  3D adjoint momentum equations and couple with vertically integrated
!  equations.
!
          DO ng=1,Ngrids
!$OMP PARALLEL DO PRIVATE(thread,subs,tile) SHARED(ng,numthreads)
            DO thread=0,numthreads-1
              subs=NtileX(ng)*NtileE(ng)/numthreads
              DO tile=subs*(thread+1)-1,subs*thread,-1
                CALL omega (ng, TILE)           ! BASIC STATE w-velocity
                CALL ad_step3d_uv (ng, TILE)
              END DO
            END DO
!$OMP END PARALLEL DO
          END DO
!
!-----------------------------------------------------------------------
!  Adjoint of recompute depths and thicknesses using the new time
!  filtered free-surface. This call was moved from "ad_step2d" to here.
!-----------------------------------------------------------------------
!
          DO ng=1,Ngrids
!$OMP PARALLEL DO PRIVATE(thread,subs,tile) SHARED(ng,numthreads)
            DO thread=0,numthreads-1
              subs=NtileX(ng)*NtileE(ng)/numthreads
              DO tile=subs*(thread+1)-1,subs*thread,-1
                CALL ad_set_depth (ng, TILE)
              END DO
            END DO
!$OMP END PARALLEL DO
          END DO
!
!-----------------------------------------------------------------------
!  Solve adjoint vertically integrated primitive equations for the
!  free-surface and barotropic momentum components.
!-----------------------------------------------------------------------
!
          LOOP_2D : DO my_iif=MAXVAL(nfast)+1,1,-1
!
!  Corrector step - Apply 2D adjoint time-step corrector scheme.  Notice
!  ==============    that there is not need for a corrector step during
!  the auxiliary (nfast+1) time-step.
!
            DO ng=1,Ngrids
              iif(ng)=my_iif
              IF (iif(ng).lt.(nfast(ng)+1)) THEN
!$OMP PARALLEL DO PRIVATE(thread,subs,tile) SHARED(ng,numthreads)
                DO thread=0,numthreads-1
                  subs=NtileX(ng)*NtileE(ng)/numthreads
                  DO tile=subs*thread,subs*(thread+1)-1,+1
                    CALL ad_step2d (ng, TILE)
                  END DO
                END DO
!$OMP END PARALLEL DO
              END IF
!
!  Set time indices for adjoint predictor step.
!
              next_indx1=3-indx1(ng)
              IF (.not.PREDICTOR_2D_STEP(ng)) THEN
                PREDICTOR_2D_STEP(ng)=.TRUE.
!>              knew(ng)=next_indx1
!>              kstp(ng)=3-knew(ng)
!>              krhs(ng)=3
!>
                kt=knew(ng)
                ks=kstp(ng)
                knew(ng)=krhs(ng)
                kstp(ng)=kt
                krhs(ng)=ks
!>              IF (my_iif.lt.(nfast(ng)+1)) indx1(ng)=next_indx1
              END IF
            END DO
!
!  Predictor step - Advance adjoint barotropic equations using 2D
!  ==============   time-step predictor scheme.  No actual time-
!  stepping is performed during the auxiliary (nfast+1) time-step.
!  It is needed to finalize the fast-time averaging of 2D fields,
!  if any, and compute the new time-evolving depths.
!
            DO ng=1,Ngrids
              IF (my_iif.le.(nfast(ng)+1)) THEN
!$OMP PARALLEL DO PRIVATE(thread,subs,tile) SHARED(ng,numthreads)
                DO thread=0,numthreads-1
                  subs=NtileX(ng)*NtileE(ng)/numthreads
                  DO tile=subs*(thread+1)-1,subs*thread,-1
                    CALL ad_step2d (ng, TILE)
                  END DO
                END DO
!$OMP END PARALLEL DO
              END IF
!
!  Set time indices for next adjoint corrector step. The
!  PREDICTOR_2D_STEP switch it is assumed to be false before the
!  first time-step.
!
              IF (PREDICTOR_2D_STEP(ng).and.                            &
     &            my_iif.le.(nfast(ng)+1)) THEN
                PREDICTOR_2D_STEP(ng)=.FALSE.
!>              IF (FIRST_2D_STEP) THEN
!>                kstp(ng)=indx1(ng)
!>              ELSE
!>                kstp(ng)=3-indx1(ng)
!>              END IF
!>              knew(ng)=3
!>              krhs(ng)=indx1(ng)
!>
                ks=knew(ng)
                knew(ng)=krhs(ng)
                krhs(ng)=ks
              END IF
            END DO

          END DO LOOP_2D

        END IF TIME_STEP

# if (defined FOUR_DVAR    && !defined IS4DVAR_SENSITIVITY) && \
      defined OBSERVATIONS
!
!-----------------------------------------------------------------------
!  If appropriate, read observation and model state at observation
!  locations.  Then, compute adjoint forcing terms due to observations.
!-----------------------------------------------------------------------
!
        DO ng=1,Ngrids
#  ifdef SENSITIVITY_4DVAR
          IF (.not.LsenPSAS(ng)) THEN
#  endif
            HalfDT=0.5_r8*dt(ng)
            IF (((time(ng)-HalfDT).le.ObsTime(ng)).and.                 &
     &          (ObsTime(ng).lt.(time(ng)+HalfDT))) THEN
              ProcessObs(ng)=.TRUE.
              CALL obs_read (ng, iADM, backward)
            ELSE
              ProcessObs(ng)=.FALSE.
            END IF
!
!$OMP PARALLEL DO PRIVATE(thread,subs,tile), SHARED(ng,numthreads)
            DO thread=0,numthreads-1
              subs=NtileX(ng)*NtileE(ng)/numthreads
              DO tile=subs*thread,subs*(thread+1)-1,+1
#  ifdef WEAK_CONSTRAINT
                CALL ad_htobs (ng, TILE, iADM)
#  else
                CALL ad_misfit (ng, TILE, iADM)
#  endif
              END DO
            END DO
!$OMP END PARALLEL DO
            IF (exit_flag.ne.NoError) RETURN
#  ifdef SENSITIVITY_4DVAR
          END IF
#  endif
        END DO
# endif

# ifdef WEAK_CONSTRAINT
!
!-----------------------------------------------------------------------
!  If appropriate, add representer coefficients (Beta hat) impulse
!  forcing to adjoint solution. Read next impulse record, if available.
!-----------------------------------------------------------------------
!
        DO ng=1,Ngrids
          IF (ProcessObs(ng)) THEN
!$OMP PARALLEL DO PRIVATE(thread,subs,tile) SHARED(ng,numthreads)
            DO thread=0,numthreads-1
              subs=NtileX(ng)*NtileE(ng)/numthreads
              DO tile=subs*thread,subs*(thread+1)-1,+1
                CALL ad_forcing (ng, TILE, kstp(ng), nstp(ng))
              END DO
            END DO
!$OMP END PARALLEL DO
          END IF
        END DO
# endif
!
!-----------------------------------------------------------------------
!  Compute adjoint right-hand-side terms for 3D equations. If
!  applicable, time-step turbulent mixing schemes.
!-----------------------------------------------------------------------
!
        DO ng=1,Ngrids
!$OMP PARALLEL DO PRIVATE(thread,subs,tile) SHARED(numthreads)
          DO thread=0,numthreads-1
            subs=NtileX(ng)*NtileE(ng)/numthreads
            DO tile=subs*thread,subs*(thread+1)-1,+1
# ifdef MY25_MIXING_NOT_YET
              CALL ad_my25_prestep (ng, TILE)
# elif defined GLS_MIXING_NOT_YET
              CALL ad_gls_prestep (ng, TILE)
# endif
              CALL ad_rhs3d (ng, TILE)
            END DO
          END DO
!$OMP END PARALLEL DO
        END DO
!
!-----------------------------------------------------------------------
!  Set adjoint free-surface to it time-averaged value.
!-----------------------------------------------------------------------
!
        DO ng=1,Ngrids
!$OMP PARALLEL DO PRIVATE(thread,subs,tile) SHARED(numthreads)
          DO thread=0,numthreads-1
            subs=NtileX(ng)*NtileE(ng)/numthreads
            DO tile=subs*thread,subs*(thread+1)-1,+1
#  ifdef DIAGNOSTICS
!!            CALL set_diags (ng, TILE)
#  endif
              CALL ad_set_zeta (ng, TILE)
            END DO
          END DO
!$OMP END PARALLEL DO
        END DO
!
!-----------------------------------------------------------------------
!  Compute adjoint vertical mixing coefficients for momentum and
!  tracers. Compute adjoint S-coordinate vertical velocity,
!  diagnostically from horizontal mass divergence.
!-----------------------------------------------------------------------
!
        DO ng=1,Ngrids
!$OMP PARALLEL DO PRIVATE(thread,subs,tile) SHARED(nstp,numthreads)
          DO thread=0,numthreads-1
            subs=NtileX(ng)*NtileE(ng)/numthreads
            DO tile=subs*(thread+1)-1,subs*thread,-1
!!            CALL wvelocity (ng, TILE, nstp(ng))
              CALL ad_omega (ng, TILE)
# if defined ANA_VMIX_NOT_YET
              CALL ad_ana_vmix (ng, TILE, iADM)
# elif defined LMD_MIXING_NOT_YET
              CALL ad_lmd_vmix (ng, TILE)
# elif defined BVF_MIXING
              CALL ad_bvf_mix (ng, TILE)
# endif
            END DO
          END DO
!$OMP END PARALLEL DO
        END DO

# ifdef SO_SEMI
!
!-----------------------------------------------------------------------
!  If stochastic optimals with respect the seminorm of chosen
!  functional, pack adjoint state surface forcing needed by the
!  dynamical propagator.
!-----------------------------------------------------------------------
!
        DO ng=1,Ngrids
          IF (MOD(iic(ng)-1,nADJ(ng)).eq.0) THEN
            SOrec(ng)=SOrec(ng)+1
!$OMP PARALLEL DO PRIVATE(thread,subs,tile)                             &
!$OMP&            SHARED(numthreads,Nstr,Nend,SOrec)
            DO thread=0,numthreads-1
              subs=NtileX(ng)*NtileE(ng)/numthreads
              DO tile=subs*thread,subs*(thread+1)-1,+1
                CALL ad_pack (ng, TILE, Nstr(ng), Nend(ng),             &
     &                        STORAGE(ng)%so_state(:,SOrec(ng)))
              END DO
            END DO
!$OMP END PARALLEL DO
          END IF
        END DO
# endif
!
!-----------------------------------------------------------------------
!  Set adjoint fields for vertical boundary conditions. Process tidal
!  forcing, if any.
!-----------------------------------------------------------------------
!
        DO ng=1,Ngrids
!$OMP PARALLEL DO PRIVATE(thread,subs,tile) SHARED(numthreads)
          DO thread=0,numthreads-1
            subs=NtileX(ng)*NtileE(ng)/numthreads
            DO tile=subs*thread,subs*(thread+1)-1,+1
# if defined SSH_TIDES_NOT_YET || defined UV_TIDES_NOT_YET
              CALL ad_set_tides (ng, TILE)
# endif
              CALL ad_set_vbc (ng, TILE)
# ifdef BBL_MODEL_NOT_YET
              CALL ad_bblm (ng, TILE)
# endif
# ifdef BULK_FLUXES_NOT_YET && !defined NL_BULK_FLUXES
              CALL ad_bulk_flux (ng, TILE)
# endif
            END DO
          END DO
!$OMP END PARALLEL DO
        END DO

# ifdef NEARSHORE_MELLOR_NOT_YET
!
!-----------------------------------------------------------------------
!  Compute radiation stress terms.
!-----------------------------------------------------------------------
!
        DO ng=1,Ngrids
!$OMP PARALLEL DO PRIVATE(thread,subs,tile) SHARED(numthreads)
          DO thread=0,numthreads-1
            subs=NtileX(ng)*NtileE(ng)/numthreads
            DO tile=subs*(thread+1)-1,subs*thread,-1
              CALL ad_radiation_stress (ng, TILE)
            END DO
          END DO
        END DO
!$OMP END PARALLEL DO
# endif

# ifdef WAVES_OCEAN_NOT_YET
!
!-----------------------------------------------------------------------
!  Couple to waves model every CoupleSteps(Iwaves) timesteps: get
!  waves/sea fluxes.
!-----------------------------------------------------------------------
!
        DO ng=1,Ngrids
          IF ((iic(ng).ne.ntstart(ng)).and.                             &
     &        MOD(iic(ng)-1,CoupleSteps(Iwaves,ng)).eq.0) THEN
!$OMP PARALLEL DO PRIVATE(thread,subs,tile) SHARED(ng,numthreads)
            DO thread=0,numthreads-1
              subs=NtileX(ng)*NtileE(ng)/numthreads
              DO tile=subs*thread,subs*(thread+1)-1,+1
                CALL waves_coupling (ng, TILE)
              END DO
            END DO
!$OMP END PARALLEL DO
          END IF
        END DO
# endif

# ifdef AIR_OCEAN_NOT_YET
!
!-----------------------------------------------------------------------
!  Couple to atmospheric model every CoupleSteps(Iatmos) timesteps: get
!  air/sea fluxes.
!-----------------------------------------------------------------------
!
        DO ng=1,Ngrids
          IF ((iic(ng).ne.ntstart(ng)).and.                             &
     &        MOD(iic(ng)-1,CoupleSteps(Iatmos,ng)).eq.0) THEN
!$OMP PARALLEL DO PRIVATE(thread,subs,tile) SHARED(ng,numthreads)
            DO thread=0,numthreads-1
              subs=NtileX(ng)*NtileE(ng)/numthreads
              DO tile=subs*(thread+1)-1,subs*thread,-1
                CALL atmos_coupling (ng, TILE)
              END DO
            END DO
!$OMP END PARALLEL DO
          END IF
        END DO
# endif
!
!-----------------------------------------------------------------------
!  Compute adjoint density related fields and horizontal mass fluxes
!  (Hz*u/n and Hz*v/m). If applicable, compute and report diagnostics
!  and accumulate time-averaged adjoint fields which needs a
!  irreversible loop in shared-memory jobs.
!-----------------------------------------------------------------------
!
        DO ng=1,Ngrids
!$OMP PARALLEL DO PRIVATE(thread,subs,tile) SHARED(ng,numthreads)
          DO thread=0,numthreads-1
            subs=NtileX(ng)*NtileE(ng)/numthreads
            DO tile=subs*thread,subs*(thread+1)-1,+1       ! irreversible
# ifndef TS_FIXED
              CALL ad_rho_eos (ng, TILE)
# endif
              CALL ad_set_massflux (ng, TILE)
              CALL ad_diag (ng, TILE)
# ifdef AD_AVERAGES
              CALL ad_set_avg (ng, TILE)
# endif
            END DO
          END DO
!$OMP END PARALLEL DO
        END DO
        IF (exit_flag.ne.NoError) RETURN
!
!-----------------------------------------------------------------------
!  Update 3D time-level indices.
!-----------------------------------------------------------------------
!
!  The original forward time-stepping indices are advanced as follows:
!
!     nstp(ng)=1+MOD(iic(ng)-ntstart(ng),2)
!     nnew(ng)=3-nstp(ng)
!     nrhs(ng)=nstp(ng)
!
!  This yields the only 2 permutations:
!
!     nstp  nnew  nrhs
!      1     2     1
!      2     1     2
!
!   With nstp=1, nnew=1 and nrhs=2 at time zero, this is equivalent to
!   the following:
!
!     nstp(ng)=nnew(ng)
!     nnew(ng)=nrhs(ng)
!     nrhs(ng)=nstp(ng)
!
!   The adjoint of this is as follows:
!
!     nstp(ng)=nrhs(ng)
!     nrhs(ng)=nnew(ng)
!     nnew(ng)=nstp(ng)
!
        DO ng=1,Ngrids
          IF (iic(ng).ne.ntend(ng)) THEN
            nrhs(ng)=nnew(ng)
            nnew(ng)=nstp(ng)
            nstp(ng)=nrhs(ng)
          END IF
        END DO
!
!-----------------------------------------------------------------------
!  If not a restart, initialize all time levels and compute other
!  initial fields.
!-----------------------------------------------------------------------
!
        DO ng=1,Ngrids
          IF (iic(ng).eq.ntend(ng)) THEN
!
!  Adjoint of initialize other state variables.
!
!$OMP PARALLEL DO PRIVATE(thread,subs,tile) SHARED(numthreads)
            DO thread=0,numthreads-1
              subs=NtileX(ng)*NtileE(ng)/numthreads
              DO tile=subs*(thread+1)-1,subs*thread,-1
                CALL ad_ini_fields (ng, TILE, iADM)
              END DO
            END DO
!$OMP END PARALLEL DO
!
!  Adjoint of initialize free-surface and compute initial level
!  thicknesses and depths.
!
!$OMP PARALLEL DO PRIVATE(thread,subs,tile) SHARED(numthreads)
            DO thread=0,numthreads-1
              subs=NtileX(ng)*NtileE(ng)/numthreads
              DO tile=subs*thread,subs*(thread+1)-1,+1
                CALL ad_set_depth (ng, TILE)
                CALL ad_ini_zeta (ng, TILE, iADM)
              END DO
            END DO
!$OMP END PARALLEL DO
          END IF
        END DO

# if defined ADJUST_STFLUX || defined ADJUST_WSTRESS
!
!-----------------------------------------------------------------------
!  Interpolate surface forcing increments and adjust surface forcing.
!  Skip first timestep.
!-----------------------------------------------------------------------
!
        DO ng=1,Ngrids
          IF (iic(ng).ne.ntstart(ng)) THEN
!$OMP PARALLEL DO PRIVATE(thread,subs,tile) SHARED(numthreads)
            DO thread=0,numthreads-1
              subs=NtileX(ng)*NtileE(ng)/numthreads
              DO tile=subs*thread,subs*(thread+1)-1,+1
                CALL ad_frc_adjust (ng, TILE, Lfout(ng))
              END DO
            END DO
!$OMP END PARALLEL DO
          END IF
        END DO
# endif

# ifdef ADJUST_BOUNDARY
!
!-----------------------------------------------------------------------
!  Interpolate open boundary increments and adjust open boundaries.
!  Skip first timestep.
!-----------------------------------------------------------------------
!
        DO ng=1,Ngrids
          IF (iic(ng).ne.ntstart(ng)) THEN
!$OMP PARALLEL DO PRIVATE(thread,subs,tile) SHARED(numthreads)
            DO thread=0,numthreads-1
              subs=NtileX(ng)*NtileE(ng)/numthreads
              DO tile=subs*thread,subs*(thread+1)-1,+1
                CALL ad_obc2d_adjust (ng, TILE, Lbout(ng))
                CALL ad_set_depth_bry (ng, TILE)
                CALL ad_obc_adjust (ng, TILE, Lbout(ng))
              END DO
            END DO
!$OMP END PARALLEL DO
          END IF
        END DO
# endif

# ifdef WEAK_CONSTRAINT
!
!-----------------------------------------------------------------------
!  Gather weak constraint forcing to storage arrays.
!-----------------------------------------------------------------------
!
        DO ng=1,Ngrids
          IF (iic(ng).ne.ntstart(ng)) THEN
!$OMP PARALLEL DO PRIVATE(thread,subs,tile) SHARED(numthreads)
            DO thread=0,numthreads-1
              subs=NtileX(ng)*NtileE(ng)/numthreads
              DO tile=subs*thread,subs*(thread+1)-1,+1
                CALL frc_ADgather (ng, TILE)
              END DO
            END DO
!$OMP END PARALLEL DO
          END IF
        END DO
# endif
!
!-----------------------------------------------------------------------
!  If appropriate, write out fields into output NetCDF files.  Notice
!  that IO data is written in delayed and serial mode.
!-----------------------------------------------------------------------
!
        DO ng=1,Ngrids
          CALL ad_output (ng)
          IF (exit_flag.ne.NoError) RETURN
        END DO

# ifdef WEAK_CONSTRAINT
!
!-----------------------------------------------------------------------
!  Copy storage arrays index 1 into index 2, and clear index 1.
!-----------------------------------------------------------------------
!
        DO ng=1,Ngrids
          IF (MOD(iic(ng)-1,nADJ(ng)).eq.0) THEN
!$OMP PARALLEL DO PRIVATE(thread,subs,tile) SHARED(numthreads)
            DO thread=0,numthreads-1
              subs=NtileX(ng)*NtileE(ng)/numthreads
              DO tile=subs*thread,subs*(thread+1)-1,+1
                CALL frc_clear (ng, TILE)
              END DO
            END DO
!$OMP END PARALLEL DO
          END IF
        END DO
# endif

# if defined AD_SENSITIVITY   || defined IS4DVAR_SENSITIVITY || \
     defined OPT_OBSERVATIONS || defined SENSITIVITY_4DVAR
!
!-----------------------------------------------------------------------
!  Add appropriate forcing terms to the adjoint model. The form of the
!  forcing depends on the functional whose sensitivity is required.
!-----------------------------------------------------------------------
!
        DO ng=1,Ngrids
#  ifdef SENSITIVITY_4DVAR
          IF (LsenPSAS(ng)) THEN
#  endif
#  if !defined AD_IMPULSE
            IF ((DendS(ng).ge.tdays(ng)).and.                           &
     &          (tdays(ng).ge.DstrS(ng))) THEN
#  endif
!$OMP PARALLEL DO PRIVATE(thread,subs,tile) SHARED(numthreads)
              DO thread=0,numthreads-1
                subs=NtileX(ng)*NtileE(ng)/numthreads
                DO tile=subs*thread,subs*(thread+1)-1,+1
                  CALL adsen_force (ng, TILE)
                END DO
              END DO
!$OMP END PARALLEL DO
#  if !defined AD_IMPULSE
            END IF
#  endif
#  ifdef SENSITIVITY_4DVAR
          END IF
#  endif
        END DO
# endif
      END DO STEP_LOOP

      RETURN
      END SUBROUTINE ad_main3d
#else
      SUBROUTINE ad_main3d
      RETURN
      END SUBROUTINE ad_main3d
#endif
