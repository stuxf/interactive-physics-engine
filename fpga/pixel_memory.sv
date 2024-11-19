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
  // Memory write address calculation (14 bits for SPRAM)
  logic [13:0] write_addr;
  assign write_addr = {write_y[5:0], write_x[5:0], 2'b00};

  // Display read address calculation (14 bits for SPRAM)
  logic [13:0] read_addr;
  assign read_addr = {row_addr[4:0], 1'b0, col_addr[5:0], 2'b00};
  logic [13:0] read_addr2;
  assign read_addr2 = {row_addr[4:0], 1'b1, col_addr[5:0], 2'b00};

  // 16-bit data signals for SPRAM
  logic [15:0] write_data;
  assign write_data = {13'b0, write_color};

  logic [15:0] pixel_data1, pixel_data2;

  // Instantiate SPRAM for top half
  SB_SPRAM256KA spram_top (
      .CLOCK(clk),
      .WREN(write_en && !write_y[5]),  // Write to top half when y[5] = 0
      .CHIPSELECT(1'b1),
      .ADDRESS(write_en ? write_addr : read_addr),
      .DATAIN(write_data),
      .MASKWREN(4'b1111),
      .DATAOUT(pixel_data1),
      .STANDBY(1'b0),
      .SLEEP(1'b0),
      .POWEROFF(1'b1)
  );

  // Instantiate SPRAM for bottom half
  SB_SPRAM256KA spram_bottom (
      .CLOCK(clk),
      .WREN(write_en && write_y[5]),  // Write to bottom half when y[5] = 1
      .CHIPSELECT(1'b1),
      .ADDRESS(write_en ? write_addr : read_addr2),
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
