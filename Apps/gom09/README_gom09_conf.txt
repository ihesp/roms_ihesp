
This File: README_gom09_conf.txt
Path: Ada: /home/jaisonk/WORK/Projects/gom_e-cesm/conf/gom09
Date: June/03/2020



1. Use gom09.h as the header file reference. Please note the following important
      differences (there are many) with the gom03.h file @ github 
      roms_ihesp/Apps/gom03/gom3.h:
      - Most importanly, the options are grouped according to a process/mechanism.
           I strongly recomment to use this style for readability.
      - no "CCSMCOUPLED" --> is this need to be present in .h file anymore? 
           Doesn't the RCESM automatically edit the .h file to add whatever options
           relevant for the coupling?
      - define CURVGRID --> Curvilinear grid
      - undef SPLINES --> This is the official recommendation on ROMS Forum.
      - define RI_HORAVG & define RI_VERAVG --> I had serveral cases of ROMS blowup
           few months into the R-CESM runs and this is one option helped me to 
           fix them. The instantaneous winds from WRF/CAM can have pretty crazy 
           patterns near islands/coast and really high values over few grid points.
           So, this is like a blanket solution for such situations even if not ideal.

2. Please use gom09.in file as the reference for your E-CESM experiment.
      - Grid size (Lm  Mm, & N) are adjusted for gom09_POPemb_grd.nc
      - NtileI and NtileJ (processors along X and Y) are 12 and 12. Edit them as
           needed.
      - A DT of 30 seconds is good for testing or running first few days/weeks
            at the least. Later we can increase the DT to higher values (say 120 
            or 180 seconds) (if we have sufficient time for such tests).
      - NTIMES: This seems like controlled by time settings in other files now. But
            I prefer some consistency and provide a realistic number here.
      - NRREC: 0 for runs from initial condition and the 1 or relevant record number
            for restart runs.
      - NRST : Change as needed
      - Output history/avg/dia --> all set to 3-hour outputs and 1-file per day
      - Based on previous 9-km runs following values are chosen for TNU2 and VISC2:
            TNU2=30 m2/s and VISC2=50 m2/s
      - Change DSTART and TIME_REF as required.
      - Change Path to INI, BRY and GRD files as required.

