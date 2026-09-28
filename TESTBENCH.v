module pwm_top_tb;

    // DUT interface signals
    reg         clk;
    reg         rst_n;
    reg         mode_sw;
    reg  [5:0]  manual_sw;
    wire        pwm_led;

    // Bookkeeping for duty-cycle measurement
    integer     high_count;
    integer     total_count;
    real        duty_pct;
    integer     i;

    //----------------------------------------------------------
    // Instantiate DUT
    //----------------------------------------------------------
    pwm_top dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .mode_sw    (mode_sw),
        .manual_sw  (manual_sw),
        .pwm_led    (pwm_led)
    );

    //----------------------------------------------------------
    // 100 MHz clock generation (10 ns period)
    //----------------------------------------------------------
    initial clk = 1'b0;
    always #5 clk = ~clk;

    //----------------------------------------------------------
    // Task: measure duty cycle over one full 8-bit counter period
    // (256 counts of the internal 25 MHz pwm clock).
    // We sample pwm_led every rising edge of the 100 MHz clk,
    // which is 4x oversampling relative to the 25 MHz pwm clock,
    // so we sample for 256*4 clk cycles to cover one PWM period.
    //----------------------------------------------------------
    task measure_duty(input [127:0] label);
        begin
            high_count  = 0;
            total_count = 256 * 4;
            for (i = 0; i < total_count; i = i + 1) begin
                @(posedge clk);
                if (pwm_led)
                    high_count = high_count + 1;
            end
            duty_pct = (high_count * 100.0) / total_count;
            $display("[%0t ns] %s -> duty cycle = %0.2f%%", $time, label, duty_pct);
        end
    endtask

    //----------------------------------------------------------
    // Stimulus
    //----------------------------------------------------------
    initial begin
        $display("=========================================================");
        $display(" PWM Brightness Controller Testbench");
        $display("=========================================================");

        // Initialize
        rst_n     = 1'b0;
        mode_sw   = 1'b0;   // 0 = auto mode, 1 = manual mode
        manual_sw = 6'd0;

        // Hold reset for a few clocks
        repeat (10) @(posedge clk);
        rst_n = 1'b1;
        $display("[%0t ns] Reset released", $time);

        //-----------------------------------------------
        // Test 1: Auto (breathing) mode
        //-----------------------------------------------
        mode_sw = 1'b0;
        $display("--- Mode = AUTO (breathing) ---");
        measure_duty("Auto mode sample 1");
        measure_duty("Auto mode sample 2");
        measure_duty("Auto mode sample 3");

        //-----------------------------------------------
        // Test 2: Manual mode - sweep several brightness values
        //-----------------------------------------------
        mode_sw = 1'b1;
        $display("--- Mode = MANUAL ---");

        manual_sw = 6'd0;    // expect duty ~ 0/255 = 0%
        repeat (5) @(posedge clk);
        measure_duty("Manual SW=0 (min brightness)");

        manual_sw = 6'd16;   // expect duty ~ 64/255 = 25.1%
        repeat (5) @(posedge clk);
        measure_duty("Manual SW=16 (~25%)");

        manual_sw = 6'd32;   // expect duty ~ 128/255 = 50.2%
        repeat (5) @(posedge clk);
        measure_duty("Manual SW=32 (~50%)");

        manual_sw = 6'd48;   // expect duty ~ 192/255 = 75.3%
        repeat (5) @(posedge clk);
        measure_duty("Manual SW=48 (~75%)");

        manual_sw = 6'd63;   // expect duty ~ 252/255 = 98.8%
        repeat (5) @(posedge clk);
        measure_duty("Manual SW=63 (max brightness)");

        //-----------------------------------------------
        // Test 3: Reset behavior mid-operation
        //-----------------------------------------------
        $display("--- Applying reset mid-test ---");
        rst_n = 1'b0;
        repeat (10) @(posedge clk);
        rst_n = 1'b1;
        repeat (5) @(posedge clk);
        measure_duty("Post-reset (manual SW=63 still held)");

        //-----------------------------------------------
        // Test 4: Switch back to auto mode and observe fade
        //-----------------------------------------------
        mode_sw = 1'b0;
        $display("--- Mode = AUTO again (observe fade continuing) ---");
        measure_duty("Auto mode sample 4");
        measure_duty("Auto mode sample 5");

        $display("=========================================================");
        $display(" Testbench complete");
        $display("=========================================================");
        $finish;
    end

    //----------------------------------------------------------
    // Safety timeout
    //----------------------------------------------------------
    initial begin
        #2_000_000; // 2 ms simulation timeout
        $display("ERROR: Testbench timeout reached");
        $finish;
    end

endmodule
