module physics_engine (
    input logic clk,
    input logic resetn,
    input logic [2:0] direction,
    output logic write_en,
    output logic [5:0] write_x,
    output logic [5:0] write_y,
    output logic [11:0] pixel_color
);

  // Constants for number of particles and trail length
  localparam NUM_PARTICLES = 10;
  localparam TRAIL_LENGTH = 3;

  // Arrays to track multiple particles
  logic [5:0] sand_x[NUM_PARTICLES];
  logic [5:0] sand_y[NUM_PARTICLES];
  logic [19:0] update_counter;

  // Trail tracking
  logic [5:0] trail_x[NUM_PARTICLES][TRAIL_LENGTH];
  logic [5:0] trail_y[NUM_PARTICLES][TRAIL_LENGTH];

  // Particle colors - unique for each particle
  logic [11:0] particle_colors[NUM_PARTICLES];

  // Border detection for current pixel being drawn
  logic is_border;
  assign is_border = (write_x == 6'd63) || (write_x == 6'd0) || (write_y == 6'd63) || (write_y == 6'd0);

  // Initial positions and colors
  logic [5:0] initial_positions[NUM_PARTICLES];
  assign initial_positions = '{
          6'd27,
          6'd28,
          6'd29,
          6'd30,
          6'd31,
          6'd32,
          6'd33,
          6'd34,
          6'd35,
          6'd36
      };

  // Direction logic
  logic signed [6:0] dir_x;
  logic signed [6:0] dir_y;
  logic [2:0] bounce_counter[NUM_PARTICLES];  // Track wall bounces

  always_comb begin
    case (direction)
      3'b000:  {dir_x, dir_y} = {7'sd0, 7'sd1};  // South
      3'b001:  {dir_x, dir_y} = {-7'sd1, 7'sd1};  // Southeast
      3'b010:  {dir_x, dir_y} = {-7'sd1, 7'sd0};  // East
      3'b011:  {dir_x, dir_y} = {-7'sd1, -7'sd1};  // Northeast
      3'b100:  {dir_x, dir_y} = {7'sd0, -7'sd1};  // North
      3'b101:  {dir_x, dir_y} = {7'sd1, -7'sd1};  // Northwest
      3'b110:  {dir_x, dir_y} = {7'sd1, 7'sd0};  // West
      3'b111:  {dir_x, dir_y} = {7'sd1, 7'sd1};  // Southwest
      default: {dir_x, dir_y} = {7'sd0, 7'sd1};  // Default South
    endcase
  end

  // Initialize particle colors in rainbow pattern
  always_ff @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      for (int i = 0; i < NUM_PARTICLES; i++) begin
        case (i % 6)
          0: particle_colors[i] <= 12'hF00;  // Red
          1: particle_colors[i] <= 12'hF80;  // Orange
          2: particle_colors[i] <= 12'hFF0;  // Yellow
          3: particle_colors[i] <= 12'h0F0;  // Green
          4: particle_colors[i] <= 12'h00F;  // Blue
          5: particle_colors[i] <= 12'hF0F;  // Purple
          default: particle_colors[i] <= 12'hFFF;
        endcase
      end
    end
  end

  // Particle motion update logic with bouncing
  always_ff @(posedge clk or negedge resetn) begin
    logic signed [6:0] next_x[NUM_PARTICLES];
    logic signed [6:0] next_y[NUM_PARTICLES];
    logic can_move[NUM_PARTICLES];
    logic will_bounce[NUM_PARTICLES];

    if (!resetn) begin
      update_counter <= 20'd0;
      for (int i = 0; i < NUM_PARTICLES; i++) begin
        sand_x[i] <= initial_positions[i];
        sand_y[i] <= 6'd31;
        bounce_counter[i] <= 3'd0;
        for (int t = 0; t < TRAIL_LENGTH; t++) begin
          trail_x[i][t] <= initial_positions[i];
          trail_y[i][t] <= 6'd31;
        end
      end
    end else begin
      update_counter <= update_counter + 20'd1;

      if (update_counter == 20'd262143) begin
        update_counter <= 20'd0;

        // Update trails first
        for (int i = 0; i < NUM_PARTICLES; i++) begin
          for (int t = TRAIL_LENGTH - 1; t > 0; t--) begin
            trail_x[i][t] <= trail_x[i][t-1];
            trail_y[i][t] <= trail_y[i][t-1];
          end
          trail_x[i][0] <= sand_x[i];
          trail_y[i][0] <= sand_y[i];
        end

        // Compute next positions with bouncing
        for (int i = 0; i < NUM_PARTICLES; i++) begin
          next_x[i] = sand_x[i] + dir_x;
          next_y[i] = sand_y[i] + dir_y;
          can_move[i] = 1'b1;
          will_bounce[i] = 1'b0;

          // Check bounds with bouncing
          if (next_x[i] <= 7'sd1 || next_x[i] >= 7'sd62) begin
            next_x[i] = sand_x[i] - dir_x;  // Reverse direction
            will_bounce[i] = 1'b1;
          end
          if (next_y[i] <= 7'sd1 || next_y[i] >= 7'sd62) begin
            next_y[i] = sand_y[i] - dir_y;  // Reverse direction
            will_bounce[i] = 1'b1;
          end

          // Update bounce counter and modify color on bounce
          if (will_bounce[i]) begin
            bounce_counter[i]  <= bounce_counter[i] + 3'd1;
            // Rotate colors on bounce
            particle_colors[i] <= {particle_colors[i][3:0], particle_colors[i][11:4]};
          end
        end

        // Check particle collisions
        for (int i = 0; i < NUM_PARTICLES; i++) begin
          for (int j = 0; j < NUM_PARTICLES; j++) begin
            if (i != j && next_x[i] == next_x[j] && next_y[i] == next_y[j]) begin
              can_move[i] = (i < j);  // Only lower index moves
            end
          end
        end

        // Update positions
        for (int i = 0; i < NUM_PARTICLES; i++) begin
          if (can_move[i]) begin
            sand_x[i] <= next_x[i][5:0];
            sand_y[i] <= next_y[i][5:0];
          end
        end
      end
    end
  end

  // Scan and write logic
  logic [5:0] scan_x;
  logic [5:0] scan_y;
  logic [3:0] write_divider;

  always_ff @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      scan_x <= 6'd0;
      scan_y <= 6'd0;
      write_divider <= 4'd0;
      write_en <= 1'b0;
    end else begin
      write_divider <= write_divider + 4'd1;
      if (write_divider == 4'd0) begin
        write_en <= 1'b1;
        write_x  <= scan_x;
        write_y  <= scan_y;
        if (scan_x == 6'd63) begin
          scan_x <= 6'd0;
          scan_y <= (scan_y == 6'd63) ? 6'd0 : scan_y + 6'd1;
        end else begin
          scan_x <= scan_x + 6'd1;
        end
      end else begin
        write_en <= 1'b0;
      end
    end
  end

  // Enhanced pixel color assignment with trails
  logic [3:0] particle_index;
  logic [3:0] trail_index;
  logic is_particle;
  logic is_trail;

  always_comb begin
    // Check if current pixel is a particle or trail
    is_particle = 1'b0;
    is_trail = 1'b0;
    particle_index = 4'd0;
    trail_index = 4'd0;

    for (int i = 0; i < NUM_PARTICLES; i++) begin
      if (write_x == sand_x[i] && write_y == sand_y[i]) begin
        is_particle = 1'b1;
        particle_index = i[3:0];
      end
      for (int t = 0; t < TRAIL_LENGTH; t++) begin
        if (write_x == trail_x[i][t] && write_y == trail_y[i][t]) begin
          is_trail = 1'b1;
          particle_index = i[3:0];
          trail_index = t[3:0];
        end
      end
    end

    // Assign color based on pixel type
    if (is_border) begin
      pixel_color = 12'hFFF;  // White border
    end else if (is_particle) begin
      pixel_color = particle_colors[particle_index];  // Particle color
    end else if (is_trail) begin
      // Fade trail color based on age
      pixel_color = {
        particle_colors[particle_index][11:8] >> trail_index,
        particle_colors[particle_index][7:4] >> trail_index,
        particle_colors[particle_index][3:0] >> trail_index
      };
    end else begin
      pixel_color = 12'h000;  // Black background
    end
  end

endmodule
