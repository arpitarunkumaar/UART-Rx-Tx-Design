// UART Tx module - Sends 8 bits of serial data, 1 start bit, 
// 1 stop bit and 0 parity bits (8-N-1). When Rx is complete, 
// o_data_avail will be driven high for 1 clock cycle.
//
// Set Parameter CLKS_PER_BIT as follows:
// CLKS_PER_BIT = (clk_freq)/(uart_freq)

module uart_tx
    #(parameter CLKS_PER_BIT = 50)
    (
        input        clk,
        input  [7:0] i_data_byte, 
        input        i_data_avail,
        output reg   o_active,
        output reg   o_done,
        output reg   o_tx
    );
     
    localparam IDLE_STATE     = 2'b00;
    localparam START_STATE    = 2'b01;
    localparam SEND_BIT_STATE = 2'b10;
    localparam STOP_STATE     = 2'b11;
    
    reg [1:0]  state = IDLE_STATE; // Initial state is IDLE
    reg [15:0] counter = 0;        // Counter to count clock ticks per bit
    reg [2:0]  bit_index = 0;      // Index for tracking which bit is being sent
    reg [7:0]  data_byte = 0;      // Byte to be transmitted, loaded from i_data_byte
    
    always @(posedge clk) begin
        case(state)
            IDLE_STATE: begin    
                o_tx      <= 1'b1;   // keep transmit line high
                o_done    <= 1'b0;  
                counter   <= 0;     
                bit_index <= 0;      
                
                // get ready for transmission and transition to next state
                if (i_data_avail == 1'b1) begin 
                    o_active  <= 1'b1;          // UART is active
                    data_byte <= i_data_byte;   
                    state     <= START_STATE;   
                    $display("TX: Moving to START_STATE with data %h", i_data_byte);
                end
                else begin
                    state    <= IDLE_STATE;     // Remain in IDLE if no data available
                    o_active <= 1'b0;          // Ensure active reg low to prevent getting stuck in endless loop in IDLE_STATE
                end
            end
                
            START_STATE: begin
                o_tx <= 1'b0;        // transmit 0 first indicating start bit
                
                if (counter < CLKS_PER_BIT-1) begin
                    // increment counter and stay in state until midpoint reached
                    counter <= counter + 1;     
                    state   <= START_STATE;     
                end
                else begin
                    counter <= 0;               
                    state   <= SEND_BIT_STATE;  
                    $display("TX: Moving to SEND_BIT_STATE");
                end
            end
            
            SEND_BIT_STATE: begin 
                o_tx <= data_byte[bit_index];  // set data for transmission
                
                if (counter < CLKS_PER_BIT-1) begin
                    counter <= counter + 1;    
                    state   <= SEND_BIT_STATE; 
                end
                else begin 
                    counter <= 0;             
                    
                    if (bit_index < 7) begin 
                        bit_index <= bit_index + 1;  
                        state     <= SEND_BIT_STATE; 
                        $display("TX: Sending bit %d", bit_index);
                    end
                    else begin 
                        bit_index <= 0;        
                        state     <= STOP_STATE; // transition to transmit stop bit 
                        $display("TX: Moving to STOP_STATE");
                    end
                end
            end
            
            // end transmission after sending stop bit
            STOP_STATE: begin
                o_tx <= 1'b1;        // stop bit indicated by 1
                
                if (counter < CLKS_PER_BIT-1) begin
                    counter <= counter + 1;   
                    state   <= STOP_STATE;     
                end
                else begin
                    o_done    <= 1'b1;         // set done FF for final clk cycle
                    counter   <= 0;            
                    state     <= IDLE_STATE;   
                    o_active  <= 1'b0;         // end of data transmission
                    $display("TX: Transmission complete");
                end
            end
            
            default:
                state <= IDLE_STATE; 
                
        endcase
    end
endmodule
