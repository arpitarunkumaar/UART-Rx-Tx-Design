module uart_top
    #(
        parameter CLKS_PER_BIT = 543
    )
    (
        input clk,
        input i_data_avail,
        input [7:0] i_data_byte,
        input i_rx,
        output o_tx,
        output o_data_avail,
        output [7:0] o_data_byte,
        output o_tx_done,
        output o_tx_active
    );

    uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) tx_inst (
        .clk(clk),
        .i_data_byte(i_data_byte),
        .i_data_avail(i_data_avail),
        .o_active(o_tx_active),
        .o_done(o_tx_done),
        .o_tx(o_tx)
    );

    uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) rx_inst (
        .clk(clk),
        .i_rx(i_rx),
        .o_data_avail(o_data_avail),
        .o_data_byte(o_data_byte)
    );

endmodule


