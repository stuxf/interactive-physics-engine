module display (
    input logic clk_in,

    // Memory Interface
    input logic write_en,
    input logic [5:0] write_x,
    input logic [5:0] write_y,
    input logic [8:0] write_color,

    // Outputs
    output logic A,
    B,
    C,
    D,
    E,
    output logic R1,
    B1,
    G1,
    output logic R2,
    B2,
    G2,
    output logic CLK,
    OE,
    LAT
);

  // State definitions
  typedef enum logic [1:0] {
    SHIFT   = 2'b00,
    LATCH   = 2'b01,
    DISPLAY = 2'b10
  } state_t;

  state_t state, nextstate;
  logic [5:0] col_count;
  logic [4:0] row_count;
  logic [7:0] display_timer;

  // BCM control
  logic [1:0] bcm_phase;  // Current BCM phase
  logic [2:0] phase_counter;  // Short counter for fast updates

  // Clock division
  logic [2:0] clk_div;
  logic       pixel_clk;

  always_ff @(posedge clk_in) begin
    clk_div <= clk_div + 1;
  end

  assign pixel_clk = clk_div[2];
  assign {E, D, C, B, A} = row_count;

  // Pixel memory instance
  pixel_memory pixel_mem (
      .clk(clk_in),
      .write_en(write_en),
      .write_x(write_x),
      .write_y(write_y),
      .write_color(write_color),
      .col_addr(col_count),
      .row_addr(row_count),
      .bcm_phase(bcm_phase),
      .R1(R1),
      .G1(G1),
      .B1(B1),
      .R2(R2),
      .G2(G2),
      .B2(B2)
  );

  // BCM phase control - keep it fast but cycle through phases regularly
  always_ff @(posedge pixel_clk) begin
    phase_counter <= phase_counter + 1;

    if (phase_counter == 3'd5) begin  // Change phase every 6 cycles
      phase_counter <= '0;
      if (bcm_phase == 2'd2) bcm_phase <= '0;
      else bcm_phase <= bcm_phase + 1;
    end
  end

  // Main state machine
  always_ff @(posedge pixel_clk) begin
    state <= nextstate;

    case (state)
      SHIFT: begin
        CLK <= ~CLK;
        if (CLK) begin
          if (col_count == 63) col_count <= '0;
          else col_count <= col_count + 1;
        end
      end

      LATCH: begin
        CLK <= 1'b0;
        display_timer <= '0;
      end

      DISPLAY: begin
        CLK <= 1'b0;
        if (display_timer == 255) begin
          if (row_count == 31) row_count <= '0;
          else row_count <= row_count + 1;
        end else begin
          display_timer <= display_timer + 1;
        end
      end

      default: CLK <= 1'b0;
    endcase
  end

  // Next state logic
  always_comb begin
    unique case (state)
      SHIFT:   nextstate = (CLK && col_count == 63) ? LATCH : SHIFT;
      LATCH:   nextstate = DISPLAY;
      DISPLAY: nextstate = (display_timer == 255) ? SHIFT : DISPLAY;
      default: nextstate = SHIFT;
    endcase
  end

  // Output logic
  always_comb begin
    unique case (state)
      SHIFT: begin
        OE  = 1'b1;
        LAT = 1'b0;
      end

      LATCH: begin
        OE  = 1'b1;
        LAT = 1'b1;
      end

      DISPLAY: begin
        LAT = 1'b0;
        // Minimal blanking at phase changes
        OE  = (phase_counter == 3'd5) ? 1'b1 : 1'b0;
      end

      default: begin
        OE  = 1'b1;
        LAT = 1'b0;
      end
    endcase
  end

endmodule
