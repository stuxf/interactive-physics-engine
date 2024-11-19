module main (
    // input logic SDI, SDO, SCLK, CE,
    output logic A,
    B,
    C,
    D,
    E,
    output logic R1,
    R2,
    B1,
    B2,
    G1,
    G2,
    output logic CLK,
    OE,
    LAT
);
  logic int_osc;
  oscillator oscillator (.clk(int_osc));
  // Memory write interface
  logic write_en;
  logic [5:0] write_x, write_y;
  logic [2:0] write_color;
  // Pattern generator registers
  logic [5:0] pattern_x, pattern_y;
  logic [3:0] write_divider;
  logic [6:0] diagonal_sum;

  // Pattern generator
  always_ff @(posedge int_osc) begin
    write_divider <= write_divider + 1;

    if (write_divider == 0) begin
      diagonal_sum <= pattern_x + pattern_y;  // Calculate sum first
      write_en <= 1'b1;
      write_x <= pattern_x;
      write_y <= pattern_y;

      // Color selection based on diagonal position
      unique case (diagonal_sum[4:2])
        3'b000:  write_color <= 3'b100;  // Red
        3'b001:  write_color <= 3'b010;  // Green
        3'b010:  write_color <= 3'b001;  // Blue
        3'b011:  write_color <= 3'b110;  // Yellow (R+G)
        3'b100:  write_color <= 3'b011;  // Cyan (G+B)
        3'b101:  write_color <= 3'b101;  // Magenta (R+B)
        3'b110:  write_color <= 3'b111;  // White
        3'b111:  write_color <= 3'b000;  // Black
        default: write_color <= 3'b100;  // Default to red
      endcase

      if (pattern_x == 63) begin
        pattern_x <= '0;
        if (pattern_y == 63) pattern_y <= '0;
        else pattern_y <= pattern_y + 1;
      end else begin
        pattern_x <= pattern_x + 1;
      end
    end else begin
      write_en <= 1'b0;
    end
  end


  display led_matrix (
      .clk_in(int_osc),
      .A(A),
      .B(B),
      .C(C),
      .D(D),
      .E(E),
      .write_en(write_en),
      .write_x(write_x),
      .write_y(write_y),
      .write_color(write_color),
      .R1(R1),
      .B1(B1),
      .G1(G1),
      .R2(R2),
      .B2(B2),
      .G2(G2),
      .CLK(CLK),
      .OE(OE),
      .LAT(LAT)
  );

endmodule
