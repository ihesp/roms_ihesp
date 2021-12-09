/*
** svn $Id: ias.h 8 2007-02-06 19:00:29Z arango $
*******************************************************************************
** Copyright (c) 2002-2007 The ROMS/TOMS Group                               **
**   Licensed under a MIT/X style license                                    **
**   See License_ROMS.txt                                                    **
*******************************************************************************
** Modification (Jaison, Dec/22/2020) : Adapted for gst03 ROMS Embedded grid 
**     - All sides are open.
** Modification (Jaison, Jun/03/2020) : Adapted for gom09 ROMS Embedded grid 
**     - North and West sides are closed, East and South sides are open.
**      
*/
/* define coupling within CESM/CCSM */
#define CCSMCOUPLED

/* Memory Management */
# undef INLINE_2DIO				/* processing 3D IO level by level */

/* Model Configuration Options */
# define SOLVE3D				/* solving 3D primitive equations */
# define CURVGRID
# define MASKING				/* solving 3D primitive equations */
# undef SPLINES				/* activate parabolic splines reconstruction */

# undef DIAGNOSTICS_UV
# undef DIAGNOSTICS_TS
# undef PERFECT_RESTART

# undef AVERAGES
# undef RST_SINGLE
# undef QCORRECTION
# undef SCORRECTION			/* freshwater flux correction */
# undef SRELAXATION
# undef SPONGE

/* Pressure Gradient Algorithm */
# define DJ_GRADPS			/* freshwater flux correction */

/* Tracer Equation Options */
# undef T_PASSIVE
# define SALINITY				/* having salinity */
# define NONLIN_EOS			/* using nonlinear equation of state */

/* Tracer advection */
# undef TS_MPDATA /* Reduces checkerboard pattern compared to  C4HADVECTION */
# define TS_A4HADVECTION	/* Hernan's Recomendation */
# define TS_A4VADVECTION	/* Hernan's Recomendation */

/* Tracer horizontal mixing */
# define DIFF_GRID			/* scale diffusion coefficients by grid size */
# define TS_DIF2				/* turn ON or OFF harmonic horizontal mixing */
# define MIX_GEO_TS			/* mixing on geopotential (constant Z) surfaces */

/* Momentum advection */
# define UV_U3HADVECTION
# define UV_C4VADVECTION

/* Momemtum horizontal mixing */
# define VISC_GRID			/* scale viscosity coefficient by grid size */
# define MIX_S_UV				/* mixing along constant S-surfaces */
# define UV_VIS2				/* turn ON or OFF harmonic horizontal mixing */

/* Momentum Equation Options */
# define UV_ADV				/* turn ON or OFF advection terms */
# define UV_COR				/* turn ON or OFF Coriolis term */
# define UV_QDRAG				/* turn ON or OFF quadratic bottom friction */
# undef  UV_SADVECTION

/* turbulence mixing scheme */
# define LMD_MIXING   /* KPP turned on */
# ifdef LMD_MIXING
#  define LMD_RIMIX 			/* add diffusivity due to shear instability */
#  define LMD_CONVEC			/* add convective mixing due to shear instability */
#  define LMD_SKPP			/* surface boundary layer KPP mixing */
#  define LMD_BKPP			/* bottom boundary layer KPP mixing */
#  define LMD_NONLOCAL		/* nonlocal transport */
#  define RI_HORAVG  
#  define RI_VERAVG
#  undef  LMD_SHAPIRO
# endif

# undef MY25_MIXING   /* MY25 turned off */
# ifdef MY25_MIXING
#  define N2S2_HORAVG
#  define KANTHA_CLAYSON
# endif

# undef  GLS_MIXING
# ifdef GLS_MIXING
#  define KANTHA_CLAYSON
#  undef  CANUTO_A
#  define N2S2_HORAVG
# endif

/* surface forcing */
# define BULK_FLUXES
# ifdef BULK_FLUXES
#  define LONGWAVE_OUT
#  define EMINUSP
#  define SOLAR_SOURCE
#  undef  DIURNAL_SRFLUX
# else
#  define ANA_SSFLUX
#  define ANA_SMFLUX
#  define ANA_STFLUX
# endif

/* define River flows */
# undef  UV_PSOURCE
# undef  TS_PSOURCE

/* Select  Biological model option */
# undef RIVER_BIOLOGY

# undef NPZD_POWELL
# ifdef NPZD_POWELL
#  define ANA_SPFLUX
#  define ANA_BPFLUX
#  undef CONST_PAR
#  define SPITZ
# endif

/* define boundary conditon: for closed boundary use "define WESTERN_WALL" */
# define RADIATION_2D			/* tangential phase speed in radiation conditions */

# define SOUTH_FSCHAPMAN
# define SOUTH_M2FLATHER
# define SOUTH_M3RADIATION
# define SOUTH_M3NUDGING
# define SOUTH_TRADIATION
# define SOUTH_TNUDGING
# define SOUTH_VOLCONS

# define EAST_FSCHAPMAN
# define EAST_M2FLATHER
# define EAST_M3RADIATION
# define EAST_M3NUDGING
# define EAST_TRADIATION
# define EAST_TNUDGING
# define EAST_VOLCONS

# define NORTH_FSCHAPMAN
# define NORTH_M2FLATHER
# define NORTH_M3RADIATION
# define NORTH_M3NUDGING
# define NORTH_TRADIATION
# define NORTH_TNUDGING
# define NORTH_VOLCONS

# define WEST_FSCHAPMAN
# define WEST_M2FLATHER
# define WEST_M3RADIATION
# define WEST_M3NUDGING
# define WEST_TRADIATION
# define WEST_TNUDGING
# define WEST_VOLCONS

/* bottom surface ANA Flux */
# define ANA_BSFLUX				/* analytical bottom salinity flux */
# define ANA_BTFLUX				/* analytical bottom temperature flux */

/* define water mass relaxation */
# undef  TCLIMATOLOGY
# undef  TCLM_NUDGING
# undef  M3CLM_NUDGING
# undef  M3CLIMATOLOGY
