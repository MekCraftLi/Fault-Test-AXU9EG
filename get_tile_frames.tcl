open_checkpoint C:/Project/ZYNQ_test/Fault-Test-AXU9EG/fault-test-hw/fault-test-hw.runs/impl_1/top_routed.dcp

set tiles [list CLEL_R_X31Y145 CLEL_R_X32Y145 CLEM_X33Y145 CLEM_X34Y145 CLEL_R_X34Y145 CLEM_X35Y145]
foreach t $tiles {
    set tile_obj [get_tiles $t]
    puts "Tile: $t"
    catch {puts "  FRAMES: [get_property FRAMES $tile_obj]"}
    catch {puts "  FRAME_OFFSET: [get_property FRAME_OFFSET $tile_obj]"}
    catch {puts "  NUM_FRAMES: [get_property NUM_FRAMES $tile_obj]"}
    catch {puts "  FAR: [get_property CONFIG_FRAME_ADDRESS $tile_obj]"}
}
exit
