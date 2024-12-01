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
  logic [8:0] write_color;

  // Pattern generator registers
  logic [5:0] pattern_x, pattern_y;
  logic [ 3:0] write_divider;
  logic [27:0] frame_counter;  // Long counter for slow changes
  logic [ 8:0] next_color;

  // All possible colors (8 colors with RGB combinations)
  parameter logic [8:0] BLACK = 9'b000_000_000;
  parameter logic [8:0] RED = 9'b111_000_000;
  parameter logic [8:0] GREEN = 9'b000_111_000;
  parameter logic [8:0] BLUE = 9'b000_000_111;
  parameter logic [8:0] YELLOW = 9'b111_111_000;
  parameter logic [8:0] CYAN = 9'b000_111_111;
  parameter logic [8:0] PURPLE = 9'b111_000_111;
  parameter logic [8:0] WHITE = 9'b111_111_111;

  // Test pattern calculations
  always_comb begin
    case (frame_counter[27:25])  // Use higher bits for slower changes
      3'd0: begin  // Full screen color cycle
        case (frame_counter[24:22])
          3'd0: next_color = RED;  // Red
          3'd1: next_color = GREEN;  // Green
          3'd2: next_color = BLUE;  // Blue
          3'd3: next_color = YELLOW;  // Yellow (R+G)
          3'd4: next_color = CYAN;  // Cyan (G+B)
          3'd5: next_color = PURPLE;  // Purple (R+B)
          3'd6: next_color = WHITE;  // White (R+G+B)
          3'd7: next_color = BLACK;  // Black (none)
        endcase
      end

      3'd1: begin  // Vertical stripes of all colors
        case (pattern_x[5:3])  // 8 vertical sections
          3'd0: next_color = BLACK;
          3'd1: next_color = RED;
          3'd2: next_color = GREEN;
          3'd3: next_color = BLUE;
          3'd4: next_color = YELLOW;
          3'd5: next_color = CYAN;
          3'd6: next_color = PURPLE;
          3'd7: next_color = WHITE;
        endcase
      end

      3'd2: begin  // Horizontal stripes of all colors
        case (pattern_y[5:3])  // 8 horizontal sections
          3'd0: next_color = BLACK;
          3'd1: next_color = RED;
          3'd2: next_color = GREEN;
          3'd3: next_color = BLUE;
          3'd4: next_color = YELLOW;
          3'd5: next_color = CYAN;
          3'd6: next_color = PURPLE;
          3'd7: next_color = WHITE;
        endcase
      end

      3'd3: begin  // 8x8 color grid
        case ({
          pattern_y[5:3], pattern_x[5:3]
        })
          6'd0: next_color = BLACK;
          6'd1: next_color = RED;
          6'd2: next_color = GREEN;
          6'd3: next_color = BLUE;
          6'd4: next_color = YELLOW;
          6'd5: next_color = CYAN;
          6'd6: next_color = PURPLE;
          6'd7: next_color = WHITE;
          6'd8: next_color = RED;
          6'd9: next_color = GREEN;
          6'd10: next_color = BLUE;
          6'd11: next_color = YELLOW;
          6'd12: next_color = CYAN;
          6'd13: next_color = PURPLE;
          6'd14: next_color = WHITE;
          6'd15: next_color = BLACK;
          default: next_color = BLACK;
        endcase
      end

      3'd4: begin  // Color blending test
        if (pattern_x < 32) begin
          if (pattern_y < 32) next_color = RED;  // Top-left: Red
          else next_color = GREEN;  // Bottom-left: Green
        end else begin
          if (pattern_y < 32) next_color = BLUE;  // Top-right: Blue
          else next_color = YELLOW;  // Bottom-right: Yellow
        end
      end

      3'd5: begin  // Moving color blocks
        case ((pattern_x + frame_counter[6:4]) % 8)
          3'd0: next_color = RED;
          3'd1: next_color = GREEN;
          3'd2: next_color = BLUE;
          3'd3: next_color = YELLOW;
          3'd4: next_color = CYAN;
          3'd5: next_color = PURPLE;
          3'd6: next_color = WHITE;
          3'd7: next_color = BLACK;
        endcase
      end

      3'd6: begin  // Checkerboard with alternating colors
        case ({
          pattern_x[3], pattern_y[3]
        })
          2'b00: next_color = RED;
          2'b01: next_color = GREEN;
          2'b10: next_color = BLUE;
          2'b11: next_color = WHITE;
        endcase
      end

      default: begin  // Rainbow pattern
        if (pattern_x < 9) next_color = RED;
        else if (pattern_x < 18) next_color = YELLOW;
        else if (pattern_x < 27) next_color = GREEN;
        else if (pattern_x < 36) next_color = CYAN;
        else if (pattern_x < 45) next_color = BLUE;
        else if (pattern_x < 54) next_color = PURPLE;
        else next_color = WHITE;
      end
    endcase
  end

  // Sequential logic
  always_ff @(posedge int_osc) begin
    frame_counter <= frame_counter + 1;
    write_divider <= write_divider + 1;

    if (write_divider == 0) begin
      write_en <= 1'b1;
      write_x <= pattern_x;
      write_y <= pattern_y;
      write_color <= next_color;

      if (pattern_x == 63) begin
        pattern_x <= '0;
        if (pattern_y == 63) pattern_y <= '0;
        else pattern_y <= pattern_y + 1;
      end else pattern_x <= pattern_x + 1;
    end else write_en <= 1'b0;
  end

  display led_matrix (
      .clk_in(int_osc),
      .write_en(write_en),
      .write_x(write_x),
      .write_y(write_y),
      .write_color(write_color),
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
