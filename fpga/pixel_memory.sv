module pixel_memory (
    input logic clk,
    // Memory write interface
    input logic write_en,
    input logic [5:0] write_x,
    input logic [5:0] write_y,
    input logic [8:0] write_color,  // 3 bits per channel (RGB)

    // Display interface
    input  logic [5:0] col_addr,
    input  logic [4:0] row_addr,
    input  logic [1:0] bcm_phase,  // Changed to 2 bits for 0-2 range
    output logic       R1,
    G1,
    B1,  // Top half colors
    output logic       R2,
    G2,
    B2  // Bottom half colors
);
  // Write to correct half based on y coordinate
  logic write_top, write_bottom;
  assign write_top = write_en && ~write_y[5];     // y < 32
  assign write_bottom = write_en && write_y[5];   // y >= 32

  // Address calculation (14 bits total)
  logic [13:0] write_addr_mapped;
  assign write_addr_mapped = {1'b0, write_y[4:0], write_x[5:0], 2'b00};

  // Read addresses for each half
  logic [13:0] read_addr_top, read_addr_bottom;
  assign read_addr_top = {1'b0, row_addr[4:0], col_addr[5:0], 2'b00};
  assign read_addr_bottom = {1'b0, row_addr[4:0], col_addr[5:0], 2'b00};

  // Expand to 16-bit data for SPRAM
  logic [15:0] write_data;
  assign write_data = {7'b0, write_color};  // 7 unused + 9 color bits

  logic [15:0] pixel_data1, pixel_data2;

  // Memory instantiation
  SB_SPRAM256KA spram_top (
      .CLOCK(clk),
      .WREN(write_top),
      .CHIPSELECT(1'b1),
      .ADDRESS(write_top ? write_addr_mapped : read_addr_top),
      .DATAIN(write_data),
      .MASKWREN(4'b1111),
      .DATAOUT(pixel_data1),
      .STANDBY(1'b0),
      .SLEEP(1'b0),
      .POWEROFF(1'b1)
  );

  SB_SPRAM256KA spram_bottom (
      .CLOCK(clk),
      .WREN(write_bottom),
      .CHIPSELECT(1'b1),
      .ADDRESS(write_bottom ? write_addr_mapped : read_addr_bottom),
      .DATAIN(write_data),
      .MASKWREN(4'b1111),
      .DATAOUT(pixel_data2),
      .STANDBY(1'b0),
      .SLEEP(1'b0),
      .POWEROFF(1'b1)
  );

  // Extract color components
  logic [2:0] r1, g1, b1, r2, g2, b2;
  assign {r1, g1, b1} = pixel_data1[8:0];
  assign {r2, g2, b2} = pixel_data2[8:0];

  // BCM output comparison
  // Use bcm_phase[1:0] for indexing 3-bit values
  assign R1 = bcm_phase < 3 ? r1[bcm_phase] : 1'b0;
  assign G1 = bcm_phase < 3 ? g1[bcm_phase] : 1'b0;
  assign B1 = bcm_phase < 3 ? b1[bcm_phase] : 1'b0;
  assign R2 = bcm_phase < 3 ? r2[bcm_phase] : 1'b0;
  assign G2 = bcm_phase < 3 ? g2[bcm_phase] : 1'b0;
  assign B2 = bcm_phase < 3 ? b2[bcm_phase] : 1'b0;
endmodule
