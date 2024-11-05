`timescale 1ns/100ps

module uart_tb();

    parameter CLK_PERIOD = 20;  // 50MHz clock
    parameter CLKS_PER_BIT = 200; 
    
    reg clk = 0;
    reg [7:0] tx_data;
    reg tx_data_valid = 0;
    wire tx_active;
    wire tx_done;
    wire serial_line;
    wire rx_data_valid;
    wire [7:0] rx_data;
    
    // Debug signals
    wire [1:0] tx_state;
    wire [1:0] rx_state;
    
    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) tx_inst (
        .clk(clk),
        .i_data_byte(tx_data),
        .i_data_avail(tx_data_valid),
        .o_active(tx_active),
        .o_done(tx_done),
        .o_tx(serial_line)
    );
    
    uart_rx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) rx_inst (
        .clk(clk),
        .i_rx(serial_line),
        .o_data_avail(rx_data_valid),
        .o_data_byte(rx_data)
    );
    
    // Clock generator
    always begin
        #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Test stimulus
    initial begin
        // Start VCD dump
        $dumpfile("uart_test.vcd");
        $dumpvars(0, uart_tb);
        
        // Initialize signals
        tx_data = 0;
        tx_data_valid = 0;
        
        // Wait for 10 clock cycles for initial settling
        repeat(10) @(posedge clk);
        
        $display("Starting UART test...");
        
        // Test single byte first
        tx_test_byte(8'h55);  // alternating 1s and 0s
        
        // Wait for reasonable amount of time
        repeat(CLKS_PER_BIT * 12) @(posedge clk);
        
        $display("First test complete, sending next byte...");
        
        tx_test_byte(8'hAA);  // alternating 0s and 1s
        
        repeat(CLKS_PER_BIT * 12) @(posedge clk);
        
        $display("Simulation complete");
        $finish;
    end
    
    task tx_test_byte;
        input [7:0] byte_to_send;
        begin
            $display("Sending byte: 0x%h at time %t", byte_to_send, $time);

            @(posedge clk);
            tx_data = byte_to_send;
            tx_data_valid = 1;

            wait(tx_active);
            tx_data_valid = 0; 
            $display("Transmission started at time %t", $time);

            wait(tx_done);
            $display("Transmission completed at time %t", $time);

            wait(rx_data_valid);
            $display("Data received: 0x%h at time %t", rx_data, $time);

            if(rx_data === byte_to_send)
                $display("PASS: Sent 0x%h, Received 0x%h", byte_to_send, rx_data);
            else
                $display("FAIL: Sent 0x%h, Received 0x%h", byte_to_send, rx_data);
        end
    endtask


    // Monitor block to track UART status
    // always @(posedge clk) begin
    //     if (tx_active || rx_data_valid)
    //         // $display("Time=%t: tx_active=%b, serial_line=%b, rx_data_valid=%b, rx_data=%h",
    //         //         $time, tx_active, serial_line, rx_data_valid, rx_data);
    // end

endmodule