module main (
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
  logic [11:0] pixel_color;  // [RRRR,GGGG,BBBB] format

  // Pattern generator registers
  logic [5:0] pattern_x, pattern_y;
  logic [ 3:0] write_divider;
  logic [27:0] frame_counter;

  // RGB color components
  logic [3:0] r, g, b;
  logic [2:0] sector;
  logic [3:0] factor;
  logic [5:0] adjusted_x;

  // Calculate rainbow colors using position
  always_comb begin
    adjusted_x = pattern_x - 1;
    sector = adjusted_x[5:3];
    factor = {adjusted_x[2:0], 1'b0};

    case (sector)
      3'b000: begin  // Red
        r = 4'hF;
        g = 4'h0;
        b = 4'h0;
      end

      3'b001: begin  // Red to Yellow
        r = 4'hF;
        g = factor;
        b = 4'h0;
      end

      3'b010: begin  // Yellow
        r = 4'hF;
        g = 4'hF;
        b = 4'h0;
      end

      3'b011: begin  // Yellow to Green
        r = 4'hF - factor;
        g = 4'hF;
        b = 4'h0;
      end

      3'b100: begin  // Green
        r = 4'h0;
        g = 4'hF;
        b = 4'h0;
      end

      3'b101: begin  // Green to Blue
        r = 4'h0;
        g = 4'hF - factor;
        b = 4'hF;
      end

      3'b110: begin  // Blue
        r = 4'h0;
        g = 4'h0;
        b = 4'hF;
      end

      3'b111: begin  // Blue to Purple
        r = factor;
        g = 4'h0;
        b = 4'hF;
      end
      default: begin  // if we hit this we did something wrong so black
        r = 0;
        g = 0;
        b = 0;
      end
    endcase

    pixel_color = {r, g, b};
  end

  // Sequential logic
  always_ff @(posedge int_osc) begin
    frame_counter <= frame_counter + 1;
    write_divider <= write_divider + 1;

    if (write_divider == 0) begin
      write_en <= 1'b1;
      write_x  <= pattern_x;
      write_y  <= pattern_y;

      if (pattern_x == 63) begin
        pattern_x <= '0;
        if (pattern_y == 63) pattern_y <= '0;
        else pattern_y <= pattern_y + 1;
      end else pattern_x <= pattern_x + 1;
    end else begin
      write_en <= 1'b0;
    end
  end

  display led_matrix (
      .clk_in(int_osc),
      .write_en(write_en),
      .write_x(write_x),
      .write_y(write_y),
      .write_color(pixel_color),
      .A(A),
      .B(B),
      .C(C),
      .D(D),
      .E(E),
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
