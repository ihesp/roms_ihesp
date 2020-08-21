
May/27/2020: E-CESM Files: New ROMS grid, ini, bry etc.
========================================================
 - pwd Cheyenne: /glade/work/jaisonk/pub/E-CESM/ROMS_gom

 - Based on the discussions in May/2020, a new GOM grid has been created following
     the POP grid's I-J lines. This grid has an approximate dx and dy of 9 km and 
     the current name is gom09_POPemb_grd.nc.

 - Initial Condition for this new grid is prepared from following POP files
       Ada dir: /tiered/user/jaisonk/WORK/Models/POP/grid/gx1v7.151008/
          pop_gx1v7_depth.nc
          domain.ocn.gx1v7.151008.nc
          g210.G_JRA.v14.gx1v7.01.pop.r.0261-01-01-00000.nc
          g210.G_JRA.v14.gx1v7.01.pop.h.nday1.0261-01-01.nc

       Initial condition: 1 -record for 0261-01-01 
       File name: gom09_N050_emb_ini_POP_JRA55_20100101.nc

 - Boundary Condition 
       - Processed 1-record for boundary condition from above initial condition file.
       - Then repeated the same boundary condition value for 10 years with 1-record 
           per year. The data for all 11 records are exactly the same. So, this file
           is good for running E-CESM for 10-11 years.
       - File name: gom09_N050_emb_bry_POP_JRA55_2010.nc


 - All the old gom03 embedded files has been moved to 202005_before dir

May/01/2020: E-CESM Configuration 
 =================================
 Based on telecon on May/01/2020, the following configuration is decided as the 
    standard one for all future testing:

 - Ini based on Brian's g210.G_JRA.v14.gx1v7.01.pop.r.0261-01-01-00000.nc
     - Brian provided the link on Cheyenne for this data:
          /glade/p/cesm/cseg/inputdata/ocn/roms/gom3/g210.G_JRA.v14.gx1v7.01
     - This data is exactly same as that Jaison obtained from Brian earlier,
          and archived on Ada at:
          /tiered/user/jaisonk/WORK/Models/POP/run/gx1v7.151008/JRA55

 - New ROMS Grid: gom03_emb_ROMS_grid.nc 
     - Ada: /tiered/user/jaisonk/WORK/Models/ROMS/grid/gom03_N050_POPemb
     - The grid name will be changed by Brian.
     - This grid boundary in CESM grid is : [268 287 245 290] ![ilo ihi jlo jhi]  i=x_indices j=y_indices
     - The ROMS grid-boundary aligns with the I-J lines of POP-grid.
     - The resolution for the  region selected from POP is increased 8-times:

            Resolution Fac    = 8
            POP  Grid size    = 20 x 46
            ROMS Grid size    = 153 x 361
            Mean ROMS dx x dy = 14.08 x 6.117 km

 - gom03_N050_emb_ini_POP_JRA55_20100101.nc - ROMS Initial condition from
       g210.G_JRA.v14.gx1v7.01.pop.r.0261-01-01-00000.nc

 - gom03_emb_ROMS_mask.nc : MAsk and Coastline for the ROMS grid.

 - fig_bathy.png : ROMS Bathymetry, with domain outline (continuous blue line)
        and corresponding POP I and J lines (dashed blue lines).
 
 - Jaison will provide (at a later time):
      ocean.in file for ROMS run-time namelist input file
      *.h file for ROMS compile-time physics options header file
