module display (
    // ... port declarations remain the same ...
    input logic clk_in,

    // Memory Interface
    input logic write_en,
    input logic [5:0] write_x,
    input logic [5:0] write_y,
    input logic [11:0] write_color,  // Changed to 12 bits

    // Row Select
    output logic A,
    B,
    C,
    D,
    E,
    // Top Half Colors
    output logic R1,
    B1,
    G1,
    // Bottom Half Colors
    output logic R2,
    B2,
    G2,
    // Control Signals
    output logic CLK,
    output logic OE,
    output logic LAT
);

  // State machine definitions remain the same
  typedef enum logic [1:0] {
    SHIFT   = 2'b00,
    LATCH   = 2'b01,
    DISPLAY = 2'b10
  } state_t;

  // Internal registers with initialization
  state_t state = SHIFT, next_state;
  logic [ 5:0] col_count = '0;  // Column counter (0-63)
  logic [ 4:0] row_count = '0;  // Row counter (0-31)
  logic [10:0] bit_timer = '0;  // Timer for BCM bit duration
  logic [ 1:0] bcm_bit = '0;  // Current bit being displayed (0-3)
  logic [ 1:0] clk_div = '0;  // Clock divider

  // BCM timing parameters (bit weights: 1, 2, 4, 8)
  logic [10:0] bit_duration;
  always_comb begin
    case (bcm_bit)
      2'd0: bit_duration = 11'd63;  // LSB duration (1 unit)
      2'd1: bit_duration = 11'd127;  // Bit 1 duration (2 units)
      2'd2: bit_duration = 11'd255;  // Bit 2 duration (4 units)
      2'd3: bit_duration = 11'd511;  // MSB duration (8 units)
      default: bit_duration = 11'd511;
    endcase
  end

  // Rest of the module remains the same but using bcm_bit as [1:0]
  // Clock division for pixel clock
  always_ff @(posedge clk_in) begin
    clk_div <= clk_div + 1;
  end

  logic pixel_clk;
  assign pixel_clk = clk_div[1];

  // Row select signals
  assign {E, D, C, B, A} = row_count;

  // Instantiate pixel memory
  pixel_memory pixel_mem (
      .clk(clk_in),
      .write_en(write_en),
      .write_x(write_x),
      .write_y(write_y),
      .write_color(write_color),
      .col_addr(col_count),
      .row_addr(row_count),
      .bcm_phase(bcm_bit),
      .R1(R1),
      .G1(G1),
      .B1(B1),
      .R2(R2),
      .G2(G2),
      .B2(B2)
  );

  // Main state machine
  always_ff @(posedge pixel_clk) begin
    state <= next_state;

    case (state)
      SHIFT: begin
        CLK <= ~CLK;
        if (CLK) begin  // Only increment on falling edge
          if (col_count == 63) col_count <= '0;
          else col_count <= col_count + 1;
        end
      end

      LATCH: begin
        CLK <= 1'b0;
        bit_timer <= '0;  // Reset timer for new bit display
      end

      DISPLAY: begin
        CLK <= 1'b0;
        if (bit_timer == bit_duration) begin
          // Move to next bit or row
          bit_timer <= '0;
          if (bcm_bit == 2'd3) begin  // Check for bit 3 using 2 bits
            bcm_bit <= 2'd0;
            if (row_count == 31) row_count <= '0;
            else row_count <= row_count + 1;
          end else begin
            bcm_bit <= bcm_bit + 1;
          end
        end else begin
          bit_timer <= bit_timer + 1;
        end
      end

      default: begin
        CLK <= 1'b0;
      end
    endcase
  end

  // Rest of the module remains the same
  // Next state logic
  always_comb begin
    unique case (state)
      SHIFT:   next_state = (CLK && col_count == 63) ? LATCH : SHIFT;
      LATCH:   next_state = DISPLAY;
      DISPLAY: next_state = (bit_timer == bit_duration) ? SHIFT : DISPLAY;
      default: next_state = SHIFT;
    endcase
  end

  // Output logic
  always_comb begin
    unique case (state)
      SHIFT: begin
        OE  = 1'b1;  // Blank during shifting
        LAT = 1'b0;
      end

      LATCH: begin
        OE  = 1'b1;  // Keep blanked during latch
        LAT = 1'b1;
      end

      DISPLAY: begin
        LAT = 1'b0;
        OE  = 1'b0;  // Display for the full bit duration
      end

      default: begin
        OE  = 1'b1;
        LAT = 1'b0;
      end
    endcase
  end

endmodule
