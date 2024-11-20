
#set_property SEVERITY {Warning} [get_drc_checks NSTD-1]
#set_property SEVERITY {Warning} [get_drc_checks UCIO-1]
#set_property SEVERITY {Warning} [get_drc_checks RTSTAT-1]

#set UnusedPin
set_property BITSTREAM.CONFIG.UNUSEDPIN Pullnone [current_design]

#system clock
set_property PACKAGE_PIN G22 [get_ports clk50m]
set_property IOSTANDARD LVCMOS33 [get_ports clk50m]
#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets u_clk_wiz_0/inst/clk_in1_clk_wiz_0]

#reset active low,
set_property PACKAGE_PIN D26 [get_ports reset_n]
set_property IOSTANDARD LVCMOS33 [get_ports reset_n]

#led
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]
set_property PACKAGE_PIN A23 [get_ports {led[0]}]
set_property PACKAGE_PIN A24 [get_ports {led[1]}]
set_property PACKAGE_PIN D23 [get_ports {led[2]}]
set_property PACKAGE_PIN C24 [get_ports {led[3]}]


# camera
set_property PACKAGE_PIN R21 [get_ports {camera_data[7]}]
set_property PACKAGE_PIN P19 [get_ports {camera_data[6]}]
set_property PACKAGE_PIN P24 [get_ports {camera_data[5]}]
set_property PACKAGE_PIN N24 [get_ports {camera_data[4]}]
set_property PACKAGE_PIN R20 [get_ports {camera_data[3]}]
set_property PACKAGE_PIN T20 [get_ports {camera_data[2]}]
set_property PACKAGE_PIN R22 [get_ports {camera_data[1]}]
set_property PACKAGE_PIN N23 [get_ports {camera_data[0]}]

set_property PACKAGE_PIN R23 [get_ports camera_sclk]
set_property PACKAGE_PIN P20 [get_ports camera_sdat]
set_property PACKAGE_PIN P23 [get_ports camera_href]
set_property PACKAGE_PIN T24 [get_ports camera_vsync]
set_property PACKAGE_PIN T25 [get_ports camera_pclk]
set_property PACKAGE_PIN T23 [get_ports camera_pwdn]
set_property PACKAGE_PIN N21 [get_ports camera_rst_n] 



set_property IOSTANDARD LVCMOS33 [get_ports {camera_data[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {camera_data[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {camera_data[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {camera_data[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {camera_data[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {camera_data[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {camera_data[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {camera_data[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports camera_sclk]   
set_property IOSTANDARD LVCMOS33 [get_ports camera_sdat]   
set_property IOSTANDARD LVCMOS33 [get_ports camera_href]   
set_property IOSTANDARD LVCMOS33 [get_ports camera_vsync]  
set_property IOSTANDARD LVCMOS33 [get_ports camera_pclk]   
#set_property IOSTANDARD LVCMOS33 [get_ports camera_xclk]   
set_property IOSTANDARD LVCMOS33 [get_ports camera_pwdn]   
set_property IOSTANDARD LVCMOS33 [get_ports camera_rst_n]  
set_property PULLUP true [get_ports camera_sclk]
set_property PULLUP true [get_ports camera_sdat]

set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets camera_pclk_IBUF]




# HDMI 
set_property IOSTANDARD TMDS_33 [get_ports hdmi_clk_p]
set_property IOSTANDARD TMDS_33 [get_ports {hdmi_dat_p[2]}]
set_property IOSTANDARD TMDS_33 [get_ports {hdmi_dat_p[1]}]
set_property IOSTANDARD TMDS_33 [get_ports {hdmi_dat_p[0]}]

set_property IOSTANDARD LVCMOS33 [get_ports HDMI_OUT_EN2]
set_property PACKAGE_PIN W20 [get_ports HDMI_OUT_EN2]

set_property PACKAGE_PIN AD26 [get_ports hdmi_clk_p]
set_property PACKAGE_PIN AB26 [get_ports {hdmi_dat_p[0]}]
set_property PACKAGE_PIN AB22 [get_ports {hdmi_dat_p[1]}]
set_property PACKAGE_PIN Y23 [get_ports {hdmi_dat_p[2]}]
