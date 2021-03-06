// Created by ihdl
`timescale 1ns/10ps

`celldefine

module PADOUT (DO, YPAD);
input  DO ;
output YPAD ;

   buf (YPAD, DO);

   specify
     // delay parameters
     specparam
       tpllh$DO$YPAD = 0.69:0.69:0.69,
       tphhl$DO$YPAD = 0.5:0.5:0.5;

     // path delays
     (DO *> YPAD) = (tpllh$DO$YPAD, tphhl$DO$YPAD);

   endspecify

endmodule

`endcelldefine
