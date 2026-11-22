`timescale 1ns / 1ps
//==============================================================================
// Файл    : spi_slave_model.v
// Модуль  : spi_slave_model - поведінкова модель SPI Slave (режим 0)
//
// Імітує зовнішній пристрій (тільки для симуляції, не синтезується):
//   - після опускання CS_N виставляє на MISO старший біт слова reply_data;
//   - по зрізу SCK виставляє наступний біт;
//   - по фронту SCK зчитує MOSI в зсувний регістр;
//   - по піднятті CS_N зберігає прийняте слово в received_data.
//==============================================================================
module spi_slave_model #(
    parameter DATA_WIDTH = 8
) (
    input  wire                  sck,
    input  wire                  cs_n,
    input  wire                  mosi,
    output wire                  miso,
    input  wire [DATA_WIDTH-1:0] reply_data,      // слово, яке Slave віддає Master-у
    output reg  [DATA_WIDTH-1:0] received_data    // слово, яке Slave прийняв від Master-а
);

    reg [DATA_WIDTH-1:0] tx_shift;   // зсувний регістр передачі
    reg [DATA_WIDTH-1:0] rx_shift;   // зсувний регістр прийому
    reg                  miso_r;     // поточний біт на MISO

    // Коли Slave не вибрано, лінія MISO утримується в 0
    assign miso = cs_n ? 1'b0 : miso_r;

    // Початок обміну: завантажити відповідь і виставити старший біт
    always @(negedge cs_n) begin
        tx_shift <= reply_data;
        miso_r   <= reply_data[DATA_WIDTH-1];
    end

    // Фронт SCK: зчитати MOSI
    always @(posedge sck) begin
        if (!cs_n)
            rx_shift <= {rx_shift[DATA_WIDTH-2:0], mosi};
    end

    // Зріз SCK: зсунути регістр передачі й виставити наступний біт
    always @(negedge sck) begin
        if (!cs_n) begin
            tx_shift <= {tx_shift[DATA_WIDTH-2:0], 1'b0};
            miso_r   <= tx_shift[DATA_WIDTH-2];
        end
    end

    // Кінець обміну: зберегти прийняте слово
    always @(posedge cs_n) begin
        received_data <= rx_shift;
    end

endmodule
