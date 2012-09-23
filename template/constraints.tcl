

# Input Delay and Output Delay
#/* Delay of input signals (Clock-to-Q, Package etc.)  */
#/* output delay -> reserved time for output signals (Holdtime etc.)   */



if {![info exist clk_freq_MHz]} {
    set clk_freq_MHz 100
}
set period [expr 1000.0 / $clk_freq_MHz]

if {![info exist input_delay_ns]} {
    set input_delay_ns [expr $period / 2.0]
}
if {![info exist output_delay_ns]} {
    set output_delay_ns [expr $period / 2.0]
}
if {![info exist clk_latency]} {
    set clk_latency [expr $period / 3.0]
}
if {![info exist clk_uncertainty]} {
    set clk_uncertainty [expr $period / 10.0]
}

global clock_pin
set clock_pin clk
set clk_name $clock_pin
create_clock -period $period $clk_name

#/* The name of the IOClock(virtual clock), frequency    */
set vperiod $period
set vclk_uncertainty $clk_uncertainty
set clk_name vclk
create_clock -period $vperiod -name $clk_name

# Set the IO constraints
#set_driving_cell  -lib_cell INVX8  [all_inputs]
set_input_delay $input_delay_ns -clock vclk [remove_from_collection [all_inputs] $clock_pin]
set_output_delay $output_delay_ns -clock vclk [all_outputs]

# Set the clock uncertainties.
set_clock_uncertainty -from $clk_name -to $clk_name $clk_uncertainty
set_clock_uncertainty -from vclk -to $clk_name $vclk_uncertainty
set_clock_uncertainty -from $clk_name -to vclk $vclk_uncertainty
set_clock_uncertainty -from vclk -to vclk $vclk_uncertainty

# Exclude high fanout nets from timing calculations.
#set_ideal_net clk

# Dont touch nets, designs etc.
