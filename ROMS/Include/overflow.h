/*
** svn $Id: overflow.h 523 2011-01-05 03:21:38Z arango $
*******************************************************************************
** Copyright (c) 2002-2011 The ROMS/TOMS Group                               **
**   Licensed under a MIT/X style license                                    **
**   See License_ROMS.txt                                                    **
*******************************************************************************
**
** Options for Gravitational Overflow Test.
**
** Application flag:   OVERFLOW
** Input script:       ocean_overflow.in
*/

#define UV_ADV
#define UV_COR
#define UV_QDRAG
#define UV_VIS2
#define MIX_S_UV
#define DJ_GRADPS
#define TS_U3HADVECTION
#define TS_SVADVECTION
#define TS_DIF2
#define MIX_ISO_TS
#define SOLVE3D
#define SPLINES
#define AVERAGES
#define ANA_GRID
#define ANA_INITIAL
#define ANA_SMFLUX
#define ANA_STFLUX
#define ANA_BTFLUX
