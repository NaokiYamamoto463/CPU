// RV32I CPU animation: pitcher stays static, the ball keeps coming, and only the batter moves.
// Background is drawn once from RLE data. Then each frame redraws the batter patch and a 4x4 ball.
// Batter patch cycles through 4 frames continuously, so the batter swings several times while the ball keeps coming.
// Batter patch: x=356, y=320, size=72x88.
// Requires MM depth >= 92 words.
// Requires DM depth >= 32006 words.
// background_setup
`MM[0] = 32'h00000293; // RLE input pointer (byte address)
`MM[1] = 32'h810003B7; // RLE output framebuffer pointer
`MM[2] = 32'h000015B7; // lui x11,0x1
`MM[3] = 32'hFFF58593; // RGB444 mask
// rle_load
`MM[4] = 32'h0002A503; // lw x10,0(x5)
`MM[5] = 32'h00428293; // addi x5,x5,4
`MM[6] = 32'h40C55313; // srai x6,x10,12
`MM[7] = 32'h00030E63; // beq x6,x0,anim_setup
`MM[8] = 32'h00B574B3; // and x9,x10,x11
// rle_pixel
`MM[9] = 32'h0093A023; // sw x9,0(x7)
`MM[10] = 32'h00438393; // addi x7,x7,4
`MM[11] = 32'hFFF30313; // addi x6,x6,-1
`MM[12] = 32'hFE031AE3; // bne x6,x0,rle_pixel
`MM[13] = 32'hFC000EE3; // beq x0,x0,rle_load
// anim_setup
`MM[14] = 32'h810C8A37; // lui x20,0x810C8
`MM[15] = 32'h590A0A13; // framebuffer patch base
`MM[16] = 32'h00007AB7; // lui x21,0x7
`MM[17] = 32'h818A8A93; // raw frame data base (byte address)
`MM[18] = 32'h00006B37; // lui x22,0x6
`MM[19] = 32'h300B0B13; // raw frame stride in bytes
`MM[20] = 32'h00001BB7; // lui x23,0x1
`MM[21] = 32'h8E0B8B93; // framebuffer row stride after each patch row
`MM[22] = 32'h00400C13; // number of batter frames
`MM[23] = 32'h00000C93; // current batter frame index
`MM[24] = 32'h000A8D33; // current batter frame data pointer
`MM[25] = 32'h81070DB7; // lui x27,0x81070
`MM[26] = 32'h300D8D93; // ball start framebuffer address
`MM[27] = 32'h000D8E33; // current ball framebuffer address
`MM[28] = 32'h00000E93; // ball position index
`MM[29] = 32'h00003F37; // lui x30,0x3
`MM[30] = 32'h800F0F13; // ball vertical step in bytes
`MM[31] = 32'h07000F93; // current ball erase color
`MM[32] = 32'h000012B7; // lui x5,0x1
`MM[33] = 32'h9F028293; // 4x4 sprite row step
`MM[34] = 32'h02600313; // index where field turns brown
`MM[35] = 32'h03500393; // total ball positions
`MM[36] = 32'h00001437; // lui x8,0x1
`MM[37] = 32'hFFF40413; // ball color white
`MM[38] = 32'h61000493; // brown erase color
// frame_draw_start
`MM[39] = 32'h000A0733; // working framebuffer pointer for batter patch
`MM[40] = 32'h000D07B3; // working raw frame data pointer
`MM[41] = 32'h05800813; // patch rows
// batter_row_loop
`MM[42] = 32'h04800893; // patch columns
// batter_col_loop
`MM[43] = 32'h0007A503; // load raw batter patch pixel
`MM[44] = 32'h00A72023; // store batter patch pixel
`MM[45] = 32'h00478793; // addi x15,x15,4
`MM[46] = 32'h00470713; // addi x14,x14,4
`MM[47] = 32'hFFF88893; // addi x17,x17,-1
`MM[48] = 32'hFE0896E3; // bne x17,x0,batter_col_loop
`MM[49] = 32'h01770733; // next patch framebuffer row
`MM[50] = 32'hFFF80813; // addi x16,x16,-1
`MM[51] = 32'hFC081EE3; // bne x16,x0,batter_row_loop
`MM[52] = 32'h000E0733; // ball working framebuffer pointer
`MM[53] = 32'h00400813; // ball rows
// ball_draw_row
`MM[54] = 32'h00400893; // ball columns
// ball_draw_col
`MM[55] = 32'h00872023; // draw one ball pixel
`MM[56] = 32'h00470713; // addi x14,x14,4
`MM[57] = 32'hFFF88893; // addi x17,x17,-1
`MM[58] = 32'hFE089AE3; // bne x17,x0,ball_draw_col
`MM[59] = 32'h00570733; // next ball row
`MM[60] = 32'hFFF80813; // addi x16,x16,-1
`MM[61] = 32'hFE0812E3; // bne x16,x0,ball_draw_row
// frame_wait
`MM[62] = 32'h00040937; // frame delay; reduce for faster animation
// wait_loop
`MM[63] = 32'hFFF90913; // addi x18,x18,-1
`MM[64] = 32'hFE091EE3; // bne x18,x0,wait_loop
`MM[65] = 32'h000E0733; // ball working framebuffer pointer for erase
`MM[66] = 32'h00400813; // ball rows
// ball_erase_row
`MM[67] = 32'h00400893; // ball columns
// ball_erase_col
`MM[68] = 32'h01F72023; // erase one ball pixel
`MM[69] = 32'h00470713; // addi x14,x14,4
`MM[70] = 32'hFFF88893; // addi x17,x17,-1
`MM[71] = 32'hFE089AE3; // bne x17,x0,ball_erase_col
`MM[72] = 32'h00570733; // next ball row
`MM[73] = 32'hFFF80813; // addi x16,x16,-1
`MM[74] = 32'hFE0812E3; // bne x16,x0,ball_erase_row
`MM[75] = 32'h001E8E93; // advance ball position index
`MM[76] = 32'h026E8463; // beq x29,x6,switch_ball_brown
// after_brown_check
`MM[77] = 32'h027E8663; // beq x29,x7,reset_ball
// after_ball_reset_check
`MM[78] = 32'h01EE0E33; // advance ball framebuffer address
// after_ball_advance
`MM[79] = 32'h001C8C93; // advance batter frame index
`MM[80] = 32'h018C8663; // beq x25,x24,reset_batter_frame
`MM[81] = 32'h016D0D33; // advance batter frame data pointer
`MM[82] = 32'hF4000AE3; // beq x0,x0,frame_draw_start
// reset_batter_frame
`MM[83] = 32'h00000C93; // wrap batter frame index to 0
`MM[84] = 32'h000A8D33; // reset batter frame data pointer
`MM[85] = 32'hF40004E3; // beq x0,x0,frame_draw_start
// switch_ball_brown
`MM[86] = 32'h61000F93; // switch ball erase color to brown dirt
`MM[87] = 32'hFC000CE3; // beq x0,x0,after_brown_check
// reset_ball
`MM[88] = 32'h000D8E33; // reset ball framebuffer address
`MM[89] = 32'h00000E93; // reset ball index to 0
`MM[90] = 32'h07000F93; // reset ball erase color to green
`MM[91] = 32'hFC0008E3; // beq x0,x0,after_ball_advance
