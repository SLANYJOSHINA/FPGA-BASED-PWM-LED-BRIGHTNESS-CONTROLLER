set_property PACKAGE_PIN Y9 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} [get_ports clk]

## ---------------------------------------------------------
## Reset - SW0
## ---------------------------------------------------------
set_property PACKAGE_PIN F22 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]

## ---------------------------------------------------------
## Mode select - SW1 (0 = auto/breathing, 1 = manual)
## ---------------------------------------------------------
set_property PACKAGE_PIN G22 [get_ports mode_sw]
set_property IOSTANDARD LVCMOS33 [get_ports mode_sw]

## ---------------------------------------------------------
## Manual brightness inputs - SW2..SW7 -> manual_sw[0..5]
## ---------------------------------------------------------
set_property PACKAGE_PIN H22 [get_ports {manual_sw[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {manual_sw[0]}]

set_property PACKAGE_PIN F21 [get_ports {manual_sw[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {manual_sw[1]}]

set_property PACKAGE_PIN H19 [get_ports {manual_sw[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {manual_sw[2]}]

set_property PACKAGE_PIN H18 [get_ports {manual_sw[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {manual_sw[3]}]

set_property PACKAGE_PIN H17 [get_ports {manual_sw[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {manual_sw[4]}]

set_property PACKAGE_PIN M15 [get_ports {manual_sw[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {manual_sw[5]}]

## ---------------------------------------------------------
## PWM LED output
## ---------------------------------------------------------
set_property PACKAGE_PIN T22 [get_ports pwm_led]
set_property IOSTANDARD LVCMOS33 [get_ports pwm_led]

set_load 5.000 [all_outputs]
set_property LOAD 5 [get_ports pwm_led]
