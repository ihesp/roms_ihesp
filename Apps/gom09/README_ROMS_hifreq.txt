

 ROMS: Hi Frequency output for debugging
+++++++++++++++++++++++++++++++++++++++++
  ROMS DT = 60 Seconds
    Time steps in 1-day: 86400/60 = 1440 time steps
    Number of records in 1-file   =  8
    Total number of files         = 1440/8 = 180 files

    with one-record every 3-time steps, it will be 180/3 = 60 files -->reasonable.


Edit roms *.in file with following fields
-------------------------------------------------

   NTIMES == 1440   ! 1-day if DT=60
       DT == 60.0d0 

     NRST == 1440

     NHIS == 3
  NDEFHIS == 24
    
1) Since we are not using AVG or DIA files, no need to change fields for these files.
2) You can use exising R-CESM executable for this.
3) gom09.in is the one used for POP bathymetry run (in ../20200720_ROMS_POPh). Try
      [user@che]$ diff /glade/work/jaisonk/pub/E-CESM/ROMS_gom/20200727_hifreq/gom09.in /glade/work/jaisonk/pub/E-CESM/ROMS_gom/20200720_ROMS_POPh/gom09.in

Edit other namelist inputs for R-CESM such that:
-------------------------------------------------
1) model run length is 1-day

