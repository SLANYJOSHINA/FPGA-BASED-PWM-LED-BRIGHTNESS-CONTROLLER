module pwm_top (
    input  wire       clk,         // 100 MHz, pin Y9
    input  wire        rst_n,       // SW0, pin F22 (active low)
    input  wire         mode_sw,     // SW1, pin G22 (0=auto, 1=manual)
    input  wire [5:0]   manual_sw,   // SW2-SW7, pins H22,F21,H19,H18,H17,M15
    output wire          pwm_led      // pin T22
);

    //----------------------------------------------------------
    // Clock divider: 100 MHz -> 25 MHz
    // Toggle every 2 input clocks => output period = 4x input
    // period => 100MHz/4 = 25MHz
    //----------------------------------------------------------
    reg [1:0] clk_div_cnt;
    reg       clk_25m;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_div_cnt <= 2'd0;
            clk_25m     <= 1'b0;
        end else begin
            if (clk_div_cnt == 2'd1) begin
                clk_div_cnt <= 2'd0;
                clk_25m     <= ~clk_25m;
            end else begin
                clk_div_cnt <= clk_div_cnt + 1'b1;
            end
        end
    end

    //----------------------------------------------------------
    // 8-bit free-running counter @ 25 MHz (PWM period counter)
    //----------------------------------------------------------
    reg [7:0] pwm_counter;

    always @(posedge clk_25m or negedge rst_n) begin
        if (!rst_n)
            pwm_counter <= 8'd0;
        else
            pwm_counter <= pwm_counter + 1'b1;
    end

    //----------------------------------------------------------
    // Auto-fade (breathing) logic
    //   - Slow clock divider so the fade is visible to the eye
    //   - Duty cycle ramps 0 -> 255 -> 0 repeatedly
    //----------------------------------------------------------
    // Slow tick generator: divide 25 MHz down to ~488 Hz update rate
    // (25,000,000 / 2^16 =~ 381 Hz), giving a full 0-255-0 fade
    // sweep roughly once per second-ish, adjustable via FADE_DIV.
    localparam integer FADE_DIV_BITS = 16;
    reg [FADE_DIV_BITS-1:0] fade_div_cnt;
    wire                    fade_tick;

    always @(posedge clk_25m or negedge rst_n) begin
        if (!rst_n)
            fade_div_cnt <= {FADE_DIV_BITS{1'b0}};
        else
            fade_div_cnt <= fade_div_cnt + 1'b1;
    end

    assign fade_tick = (fade_div_cnt == {FADE_DIV_BITS{1'b0}});

    reg [7:0] auto_duty;
    reg       fade_dir;   // 1 = counting up, 0 = counting down

    always @(posedge clk_25m or negedge rst_n) begin
        if (!rst_n) begin
            auto_duty <= 8'd0;
            fade_dir  <= 1'b1;
        end else if (fade_tick) begin
            if (fade_dir) begin
                if (auto_duty == 8'd255) begin
                    fade_dir  <= 1'b0;
                end else begin
                    auto_duty <= auto_duty + 1'b1;
                end
            end else begin
                if (auto_duty == 8'd0) begin
                    fade_dir  <= 1'b1;
                end else begin
                    auto_duty <= auto_duty - 1'b1;
                end
            end
        end
    end

    //----------------------------------------------------------
    // Manual mode: SW2-SW7 (6 bits) scaled to 8-bit duty cycle
    // by shifting left by 2 (equivalent to x4)
    //----------------------------------------------------------
    wire [7:0] manual_duty;
    assign manual_duty = {manual_sw, 2'b00};

    //----------------------------------------------------------
    // Duty cycle select: manual vs auto
    //----------------------------------------------------------
    reg [7:0] duty_cycle;

    always @(posedge clk_25m or negedge rst_n) begin
        if (!rst_n)
            duty_cycle <= 8'd0;
        else if (mode_sw)
            duty_cycle <= manual_duty;   // manual mode
        else
            duty_cycle <= auto_duty;     // auto (breathing) mode
    end

    //----------------------------------------------------------
    // PWM output: high while counter < duty_cycle
    //----------------------------------------------------------
    assign pwm_led = (pwm_counter < duty_cycle);

endmodule


