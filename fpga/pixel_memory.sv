/*
 * Stephen Xu
 * November 19th, 2024
 * stxu@g.hmc.edu
 * This is the pixel memory for our display
 * Outputs RGB1 and RGB2 data
 * Write 12 bits at a time
 */
module pixel_memory (
    input logic clk,
    // Memory write interface
    input logic write_en,
    input logic [5:0] write_x,
    input logic [5:0] write_y,
    input logic [11:0] write_color,  // 4 bits per channel (RGB)

    // Display interface
    input logic [5:0] col_addr,
    input logic [4:0] row_addr,
    input logic [1:0] bcm_phase,
    output logic R1,
    G1,
    B1,  // Top half colors
    output logic R2,
    G2,
    B2  // Bottom half colors
);
  // Write enable for each half
  logic write_top, write_bottom;
  assign write_top = write_en && !write_y[5];
  assign write_bottom = write_en && write_y[5];

  // Address calculation - padded to 14 bits
  logic [13:0] write_addr, read_addr;
  assign write_addr = {1'b0, write_y[4:0], write_x, 2'b00};
  assign read_addr  = {1'b0, row_addr, col_addr, 2'b00};

  // 16-bit data for SPRAM
  logic [15:0] write_data;
  assign write_data = {4'b0, write_color};  // 4 unused + 12 color bits

  logic [15:0] pixel_data1, pixel_data2;

  // Top half memory
  SB_SPRAM256KA spram_top (
      .CLOCK(clk),
      .WREN(write_top),
      .CHIPSELECT(1'b1),
      .ADDRESS(write_top ? write_addr : read_addr),
      .DATAIN(write_data),
      .MASKWREN(4'b1111),
      .DATAOUT(pixel_data1),
      .STANDBY(1'b0),
      .SLEEP(1'b0),
      .POWEROFF(1'b1)
  );

  // Bottom half memory
  SB_SPRAM256KA spram_bottom (
      .CLOCK(clk),
      .WREN(write_bottom),
      .CHIPSELECT(1'b1),
      .ADDRESS(write_bottom ? write_addr : read_addr),
      .DATAIN(write_data),
      .MASKWREN(4'b1111),
      .DATAOUT(pixel_data2),
      .STANDBY(1'b0),
      .SLEEP(1'b0),
      .POWEROFF(1'b1)
  );

  // Color component extraction
  logic [3:0] r1, g1, b1, r2, g2, b2;
  assign {r1, g1, b1} = pixel_data1[11:0];
  assign {r2, g2, b2} = pixel_data2[11:0];

  // BCM output
  assign R1 = r1[bcm_phase];
  assign G1 = g1[bcm_phase];
  assign B1 = b1[bcm_phase];
  assign R2 = r2[bcm_phase];
  assign G2 = g2[bcm_phase];
  assign B2 = b2[bcm_phase];

endmodule
