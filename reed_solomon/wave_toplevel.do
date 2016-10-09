onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix hexadecimal /rs_16_14_control_tb_top/CONTROL_INST/clk_i
add wave -noupdate -radix hexadecimal /rs_16_14_control_tb_top/CONTROL_INST/rst_n_i
add wave -noupdate -divider {RAM INTF}
add wave -noupdate -radix hexadecimal /rs_16_14_control_tb_top/CONTROL_INST/ram_data_o
add wave -noupdate -radix hexadecimal /rs_16_14_control_tb_top/CONTROL_INST/ram_data_i
add wave -noupdate -radix hexadecimal /rs_16_14_control_tb_top/CONTROL_INST/ram_wr_en_o
add wave -noupdate -radix hexadecimal /rs_16_14_control_tb_top/CONTROL_INST/ram_rd_en_o
add wave -noupdate -radix hexadecimal /rs_16_14_control_tb_top/CONTROL_INST/ram_address_o
add wave -noupdate -divider {HW CONTROL}
add wave -noupdate -radix hexadecimal /rs_16_14_control_tb_top/CONTROL_INST/start_encode_i
add wave -noupdate -radix hexadecimal /rs_16_14_control_tb_top/CONTROL_INST/start_decode_i
add wave -noupdate -radix hexadecimal /rs_16_14_control_tb_top/CONTROL_INST/encode_done_o
add wave -noupdate -radix hexadecimal /rs_16_14_control_tb_top/CONTROL_INST/decode_done_o
add wave -noupdate -radix hexadecimal /rs_16_14_control_tb_top/CONTROL_INST/dec_cerr_o
add wave -noupdate -radix hexadecimal /rs_16_14_control_tb_top/CONTROL_INST/dec_ncerr_o
add wave -noupdate -divider {HPS INTF}
add wave -noupdate -radix hexadecimal /rs_16_14_control_tb_top/CONTROL_INST/hps_mem_stb_i
add wave -noupdate -radix hexadecimal /rs_16_14_control_tb_top/CONTROL_INST/hps_mem_write_i
add wave -noupdate -radix hexadecimal /rs_16_14_control_tb_top/CONTROL_INST/hps_mem_wdata_i
add wave -noupdate -radix hexadecimal /rs_16_14_control_tb_top/CONTROL_INST/hps_mem_addr_i
add wave -noupdate -radix hexadecimal /rs_16_14_control_tb_top/CONTROL_INST/hps_mem_rdata_o
add wave -noupdate -radix hexadecimal /rs_16_14_control_tb_top/CONTROL_INST/hps_mem_rdy_o
add wave -noupdate -radix hexadecimal /rs_16_14_control_tb_top/CONTROL_INST/hps_rs_exec_i
add wave -noupdate -radix hexadecimal /rs_16_14_control_tb_top/CONTROL_INST/hps_rs_en_decn_i
add wave -noupdate -radix hexadecimal /rs_16_14_control_tb_top/CONTROL_INST/hps_rs_addr_i
add wave -noupdate -divider {RS_CTRL INTERNAL}
add wave -noupdate -radix hexadecimal /rs_16_14_control_tb_top/CONTROL_INST/crt_state_s
add wave -noupdate -radix hexadecimal /rs_16_14_control_tb_top/CONTROL_INST/ram_address_s
add wave -noupdate -radix hexadecimal /rs_16_14_control_tb_top/CONTROL_INST/rs_base_address
add wave -noupdate -radix hexadecimal /rs_16_14_control_tb_top/CONTROL_INST/rs_data_original_s
add wave -noupdate -radix hexadecimal /rs_16_14_control_tb_top/CONTROL_INST/rs_enc_result_s
add wave -noupdate -radix hexadecimal /rs_16_14_control_tb_top/CONTROL_INST/rs_dec_result_s
add wave -noupdate -divider {HPS BUS INTF}
add wave -noupdate -radix hexadecimal /rs_16_14_control_tb_top/hps_rs_control_bridge_inst/chipselect_i
add wave -noupdate -radix hexadecimal /rs_16_14_control_tb_top/hps_rs_control_bridge_inst/read_i
add wave -noupdate -radix hexadecimal /rs_16_14_control_tb_top/hps_rs_control_bridge_inst/write_i
add wave -noupdate -radix hexadecimal /rs_16_14_control_tb_top/hps_rs_control_bridge_inst/address_i
add wave -noupdate -radix hexadecimal /rs_16_14_control_tb_top/hps_rs_control_bridge_inst/writedata_i
add wave -noupdate -radix hexadecimal /rs_16_14_control_tb_top/hps_rs_control_bridge_inst/readdata_o
add wave -noupdate -radix hexadecimal /rs_16_14_control_tb_top/hps_rs_control_bridge_inst/readdatavalid_o
add wave -noupdate -radix hexadecimal /rs_16_14_control_tb_top/hps_rs_control_bridge_inst/waitrequest_o
add wave -noupdate -radix hexadecimal /rs_16_14_control_tb_top/hps_rs_control_bridge_inst/crt_state_s
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 247
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {5444 ps}
