module pattern_generator (
    input logic clk,

    output logic write_en,
    output logic [5:0] write_x,
    output logic [5:0] write_y,
    output logic [11:0] pixel_color  // [RRRR,GGGG,BBBB] format
);
  // Pattern generator registers
  logic [5:0] pattern_x, pattern_y;
  logic [3:0] write_divider;
  logic [27:0] frame_counter;

  // Border detection
  logic is_border;
  assign is_border = (pattern_x == 6'd0) || (pattern_x == 6'd1) ||
                      (pattern_y == 6'd0) || (pattern_y == 6'd63);

  // RGB color components
  logic [3:0] r, g, b;
  logic [2:0] sector;
  logic [3:0] factor;
  logic [5:0] adjusted_x;

  // Update divider and frame counter
  always_ff @(posedge clk) begin
    frame_counter <= frame_counter + 28'd1;
    write_divider <= write_divider + 4'd1;
  end

  // Calculate rainbow colors using position
  always_comb begin
    adjusted_x = pattern_x - 6'd1;
    sector = adjusted_x[5:3];
    factor = {adjusted_x[2:0], 1'b0};

    if (is_border) begin
      r = 4'hF;
      g = 4'hF;
      b = 4'hF;
    end else begin
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
        default: begin
          r = 4'h0;
          g = 4'h0;
          b = 4'h0;
        end
      endcase
    end

    pixel_color = {r, g, b};
  end

  // Sequential logic for pattern generation
  always_ff @(posedge clk) begin
    if (write_divider == 4'd0) begin
      write_en <= 1'b1;
      write_x  <= pattern_x;
      write_y  <= pattern_y;

      if (pattern_x == 6'd63) begin
        pattern_x <= 6'd0;
        if (pattern_y == 6'd63) begin
          pattern_y <= 6'd0;
        end else begin
          pattern_y <= pattern_y + 6'd1;
        end
      end else begin
        pattern_x <= pattern_x + 6'd1;
      end
    end else begin
      write_en <= 1'b0;
    end
  end

endmodule