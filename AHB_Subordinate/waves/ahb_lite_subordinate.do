onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_ahb_lite_subordinate/DUT/clk
add wave -noupdate /tb_ahb_lite_subordinate/DUT/n_rst
add wave -noupdate -divider {AHB Signals}
add wave -noupdate -expand -group {AHB Signals} /tb_ahb_lite_subordinate/DUT/hsel
add wave -noupdate -expand -group {AHB Signals} /tb_ahb_lite_subordinate/DUT/haddr
add wave -noupdate -expand -group {AHB Signals} /tb_ahb_lite_subordinate/DUT/htrans
add wave -noupdate -expand -group {AHB Signals} /tb_ahb_lite_subordinate/DUT/hsize
add wave -noupdate -expand -group {AHB Signals} /tb_ahb_lite_subordinate/DUT/hwrite
add wave -noupdate -expand -group {AHB Signals} /tb_ahb_lite_subordinate/DUT/hwdata
add wave -noupdate -expand -group {AHB Signals} /tb_ahb_lite_subordinate/DUT/hrdata
add wave -noupdate -expand -group {AHB Signals} /tb_ahb_lite_subordinate/DUT/hready
add wave -noupdate -expand -group {AHB Signals} /tb_ahb_lite_subordinate/DUT/hresp
add wave -noupdate -expand -group {AHB Signals} /tb_ahb_lite_subordinate/DUT/hburst
add wave -noupdate -divider RX_Signals
add wave -noupdate -group RX_Signals /tb_ahb_lite_subordinate/DUT/rx_packet
add wave -noupdate -group RX_Signals /tb_ahb_lite_subordinate/DUT/rx_data_ready
add wave -noupdate -group RX_Signals /tb_ahb_lite_subordinate/DUT/rx_transfer_active
add wave -noupdate -group RX_Signals /tb_ahb_lite_subordinate/DUT/rx_error
add wave -noupdate -group RX_Signals /tb_ahb_lite_subordinate/DUT/rx_data
add wave -noupdate -group RX_Signals /tb_ahb_lite_subordinate/DUT/get_rx_data
add wave -noupdate -divider TX_Signals
add wave -noupdate -group TX_signals /tb_ahb_lite_subordinate/DUT/tx_data
add wave -noupdate -group TX_signals /tb_ahb_lite_subordinate/DUT/tx_packet
add wave -noupdate -group TX_signals /tb_ahb_lite_subordinate/DUT/store_tx_data
add wave -noupdate -group TX_signals /tb_ahb_lite_subordinate/DUT/tx_transfer_active
add wave -noupdate -group TX_signals /tb_ahb_lite_subordinate/DUT/tx_error
add wave -noupdate -divider {Other Output Signals}
add wave -noupdate /tb_ahb_lite_subordinate/DUT/d_mode
add wave -noupdate /tb_ahb_lite_subordinate/DUT/buffer_occupancy
add wave -noupdate /tb_ahb_lite_subordinate/DUT/clear
add wave -noupdate -divider State
add wave -noupdate /tb_ahb_lite_subordinate/DUT/current_state
add wave -noupdate /tb_ahb_lite_subordinate/DUT/next_state
add wave -noupdate -divider {Internal Registers}
add wave -noupdate -expand -group {Internal Registers} /tb_ahb_lite_subordinate/DUT/data_buffer_reg
add wave -noupdate -expand -group {Internal Registers} /tb_ahb_lite_subordinate/DUT/status_reg
add wave -noupdate -expand -group {Internal Registers} /tb_ahb_lite_subordinate/DUT/error_reg
add wave -noupdate -expand -group {Internal Registers} /tb_ahb_lite_subordinate/DUT/buffer_occu_reg
add wave -noupdate -expand -group {Internal Registers} /tb_ahb_lite_subordinate/DUT/tx_ctrl_reg
add wave -noupdate -expand -group {Internal Registers} /tb_ahb_lite_subordinate/DUT/flush_ctrl_reg
add wave -noupdate -divider {Pipeline and RAW}
add wave -noupdate -expand -group {Pipeline and RAW} /tb_ahb_lite_subordinate/DUT/haddr_pipeline
add wave -noupdate -expand -group {Pipeline and RAW} /tb_ahb_lite_subordinate/DUT/haddr_pipeline_2
add wave -noupdate -expand -group {Pipeline and RAW} /tb_ahb_lite_subordinate/DUT/hwrite_pipeline
add wave -noupdate -expand -group {Pipeline and RAW} /tb_ahb_lite_subordinate/DUT/hsize_pipeline
add wave -noupdate -expand -group {Pipeline and RAW} /tb_ahb_lite_subordinate/DUT/hsize_pipeline_2
add wave -noupdate -expand -group {Pipeline and RAW} /tb_ahb_lite_subordinate/DUT/valid_access_pipeline
add wave -noupdate -expand -group {Pipeline and RAW} /tb_ahb_lite_subordinate/DUT/hwdata_pipeline
add wave -noupdate -expand -group {Pipeline and RAW} /tb_ahb_lite_subordinate/DUT/raw_pipeline
add wave -noupdate -expand -group {Pipeline and RAW} /tb_ahb_lite_subordinate/DUT/valid_address
add wave -noupdate -expand -group {Pipeline and RAW} /tb_ahb_lite_subordinate/DUT/valid_write
add wave -noupdate -expand -group {Pipeline and RAW} /tb_ahb_lite_subordinate/DUT/valid_access
add wave -noupdate -expand -group {Pipeline and RAW} /tb_ahb_lite_subordinate/DUT/raw
add wave -noupdate -expand -group {Pipeline and RAW} /tb_ahb_lite_subordinate/DUT/error
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {287954 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 118
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
WaveRestoreZoom {222117 ps} {396344 ps}
