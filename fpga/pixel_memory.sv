module pixel_memory (
    input logic clk,
    // Memory write interface
    input logic write_en,
    input logic [5:0] write_x,  // 0-63 x coordinate
    input logic [5:0] write_y,  // 0-63 y coordinate
    input logic [2:0] write_color,  // RGB value for pixel

    // Display interface
    input  logic [5:0] col_addr,  // Current column being displayed
    input  logic [4:0] row_addr,  // Current row being displayed
    output logic       R1,
    G1,
    B1,  // Top half colors
    output logic       R2,
    G2,
    B2  // Bottom half colors
);
  // Write to correct half based on y coordinate
  logic write_top, write_bottom;
  assign write_top = write_en && ~write_y[5];  // y < 32
  assign write_bottom = write_en && write_y[5];  // y >= 32

  // Address calculation - make sure we have 14 bits total
  logic [13:0] write_addr_mapped;
  assign write_addr_mapped = {1'b0, write_y[4:0], write_x[5:0], 2'b00};  // 1 + 5 + 6 + 2 = 14 bits

  // Read addresses for each half - also 14 bits
  logic [13:0] read_addr_top;
  logic [13:0] read_addr_bottom;
  assign read_addr_top = {1'b0, row_addr[4:0], col_addr[5:0], 2'b00};  // 1 + 5 + 6 + 2 = 14 bits
  assign read_addr_bottom = {1'b0, row_addr[4:0], col_addr[5:0], 2'b00};  // 1 + 5 + 6 + 2 = 14 bits

  // 16-bit data signals for SPRAM
  logic [15:0] write_data;
  assign write_data = {13'b0, write_color};

  logic [15:0] pixel_data1, pixel_data2;

  // Top half memory
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

  // Bottom half memory
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

  // Assign RGB outputs (taking only the lowest 3 bits)
  assign {R1, G1, B1} = pixel_data1[2:0];
  assign {R2, G2, B2} = pixel_data2[2:0];

endmodule
