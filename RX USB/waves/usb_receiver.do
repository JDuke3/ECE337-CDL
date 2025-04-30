onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_usb_receiver/clk
add wave -noupdate /tb_usb_receiver/n_rst
add wave -noupdate /tb_usb_receiver/DP_IN
add wave -noupdate /tb_usb_receiver/DM_IN
add wave -noupdate /tb_usb_receiver/RX_Data_ready
add wave -noupdate /tb_usb_receiver/RX_Transfer_Active
add wave -noupdate /tb_usb_receiver/RX_Error
add wave -noupdate /tb_usb_receiver/Flush
add wave -noupdate /tb_usb_receiver/RX_Packet
add wave -noupdate /tb_usb_receiver/Store_RX_Packet_Data
add wave -noupdate /tb_usb_receiver/RX_Packet_Data
add wave -noupdate /tb_usb_receiver/test_num
add wave -noupdate /tb_usb_receiver/expected_RX_Data_ready
add wave -noupdate /tb_usb_receiver/expected_RX_Transfer_Active
add wave -noupdate /tb_usb_receiver/expected_RX_Error
add wave -noupdate /tb_usb_receiver/expected_Flush
add wave -noupdate /tb_usb_receiver/expected_RX_Packet
add wave -noupdate /tb_usb_receiver/expected_Store_RX_Packet_Data
add wave -noupdate /tb_usb_receiver/expected_RX_Packet_Data
add wave -noupdate /tb_usb_receiver/DUT/rxrcu/state
add wave -noupdate /tb_usb_receiver/DUT/shift_strobe
add wave -noupdate /tb_usb_receiver/DUT/byte_done
add wave -noupdate /tb_usb_receiver/DUT/d_enable
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {429775 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
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
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {987 ns}
