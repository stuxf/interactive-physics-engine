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
  logic [7:0] animation_counter;
  logic [2:0] current_frame;
  logic [2:0] next_color;

  // Combinational logic for pattern calculations
  always_comb begin
    case (current_frame)
      3'd0: begin  // Expanding circles
        automatic logic [7:0] dx = {2'b0, pattern_x} - 8'd32;
        automatic logic [7:0] dy = {2'b0, pattern_y} - 8'd32;
        automatic logic [7:0] center_dist = ((dx * dx) + (dy * dy)) >> 6;
        next_color = (center_dist[2:0] + animation_counter[7:5] < 3'h4) ? 3'b100 : 3'b000;
      end

      3'd1: begin  // Moving sine wave
        automatic logic [7:0] wave_pos = {2'b0, pattern_y} + animation_counter;
        next_color = (pattern_x[5:3] == wave_pos[5:3]) ? 3'b010 : 3'b000;
      end

      3'd2: begin  // Checkerboard pattern that shifts
        next_color = ((pattern_x[3] ^ pattern_y[3] ^ animation_counter[5]) ? 3'b001 : 3'b000);
      end

      3'd3: begin  // Rain effect
        automatic logic [2:0] drop_pos = pattern_y[2:0] + animation_counter[2:0];
        next_color = (pattern_x[2:0] == drop_pos) ? 3'b011 : 3'b000;
      end

      default: begin  // Rotating line
        automatic logic [5:0] x_rot = pattern_x + animation_counter[7:2];
        automatic logic [5:0] y_rot = pattern_y + animation_counter[7:2];
        next_color = ({x_rot[5:3] + y_rot[5:3]} == 3'b000) ? 3'b111 : 3'b000;
      end
    endcase
  end

  // Sequential logic for state updates
  always_ff @(posedge int_osc) begin
    write_divider <= write_divider + 1;

    if (write_divider == 0) begin
      write_en <= 1'b1;
      write_x <= pattern_x;
      write_y <= pattern_y;
      write_color <= next_color;

      // Increment animation counter and frame
      if (pattern_x == 63 && pattern_y == 63) begin
        animation_counter <= animation_counter + 1;
        if (animation_counter == 0) begin
          current_frame <= current_frame + 1;
        end
      end

      // Increment pattern coordinates
      if (pattern_x == 63) begin
        pattern_x <= '0;
        if (pattern_y == 63) begin
          pattern_y <= '0;
        end else begin
          pattern_y <= pattern_y + 1;
        end
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
