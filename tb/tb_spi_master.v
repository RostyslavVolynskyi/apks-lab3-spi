`timescale 1ns / 1ps
//==============================================================================
// Файл    : tb_spi_master.v
// Модуль  : tb_spi_master - testbench для spi_master
//
// Що робить:
//   - генерує тактовий сигнал clk (100 МГц) та сигнал скидання rst;
//   - по черзі запускає кілька обмінів: Master передає слово по MOSI, а модель
//     Slave одночасно віддає своє слово по MISO;
//   - після кожного обміну перевіряє:
//       (1) Slave прийняв саме те слово, яке передав Master (перевірка Tx);
//       (2) Master прийняв саме те слово, яке віддав Slave (перевірка Rx);
//   - виводить у консоль PASS/FAIL та підсумок, записує осцилограму у VCD.
//==============================================================================
module tb_spi_master;

    localparam DATA_WIDTH = 8;
    localparam CLK_DIV    = 4;      // SCK = 100 МГц / (2*4) = 12.5 МГц
    localparam CLK_PERIOD = 10;     // 10 нс -> 100 МГц

    // Сигнали
    reg                   clk = 1'b0;
    reg                   rst = 1'b1;
    reg                   start = 1'b0;
    reg  [DATA_WIDTH-1:0] tx_data = {DATA_WIDTH{1'b0}};
    reg  [DATA_WIDTH-1:0] slave_reply = {DATA_WIDTH{1'b0}};
    wire                  sck, mosi, miso, cs_n, busy, done, rx_valid;
    wire [DATA_WIDTH-1:0] rx_data;
    wire [DATA_WIDTH-1:0] slave_received;

    integer errors = 0;
    integer tests  = 0;

    // Перевіряємий модуль (DUT)
    spi_master #(
        .DATA_WIDTH (DATA_WIDTH),
        .CLK_DIV    (CLK_DIV)
    ) dut (
        .clk      (clk),
        .rst      (rst),
        .start    (start),
        .tx_data  (tx_data),
        .miso     (miso),
        .sck      (sck),
        .mosi     (mosi),
        .cs_n     (cs_n),
        .busy     (busy),
        .done     (done),
        .rx_data  (rx_data),
        .rx_valid (rx_valid)
    );

    // Модель зовнішнього пристрою (Slave)
    spi_slave_model #(
        .DATA_WIDTH (DATA_WIDTH)
    ) slave (
        .sck           (sck),
        .cs_n          (cs_n),
        .mosi          (mosi),
        .miso          (miso),
        .reply_data    (slave_reply),
        .received_data (slave_received)
    );

    // Генерація тактового сигналу
    always #(CLK_PERIOD/2) clk = ~clk;

    // Один обмін: Master передає m_tx, Slave відповідає s_reply
    task transfer(input [DATA_WIDTH-1:0] m_tx, input [DATA_WIDTH-1:0] s_reply);
        begin
            slave_reply = s_reply;
            tx_data     = m_tx;
            @(posedge clk); start <= 1'b1;     // імпульс start тривалістю 1 такт
            @(posedge clk); start <= 1'b0;
            @(posedge done);                   // чекаємо завершення обміну
            @(posedge clk); #1;
            tests = tests + 1;
            if ((slave_received === m_tx) && (rx_data === s_reply))
                $display("[PASS] #%0d  Master TX=0x%02h -> Slave RX=0x%02h | Slave TX=0x%02h -> Master RX=0x%02h  (t=%0t)",
                         tests, m_tx, slave_received, s_reply, rx_data, $time);
            else begin
                errors = errors + 1;
                $display("[FAIL] #%0d  Master TX=0x%02h -> Slave RX=0x%02h | Slave TX=0x%02h -> Master RX=0x%02h  (t=%0t)",
                         tests, m_tx, slave_received, s_reply, rx_data, $time);
            end
            repeat (4) @(posedge clk);
        end
    endtask

    // Основний сценарій
    initial begin
        $dumpfile("sim/spi_wave.vcd");
        $dumpvars(0, tb_spi_master);

        $display("=== SPI Master testbench: mode 0, %0d bit, CLK_DIV=%0d ===", DATA_WIDTH, CLK_DIV);

        // Скидання
        repeat (5) @(posedge clk);
        rst = 1'b0;
        repeat (3) @(posedge clk);

        // Тестові обміни
        transfer(8'hA5, 8'h3C);
        transfer(8'h00, 8'hFF);
        transfer(8'hFF, 8'h00);
        transfer(8'h55, 8'hAA);
        transfer(8'h81, 8'h7E);
        transfer(8'h3C, 8'hC3);

        if (errors == 0)
            $display("RESULT: ALL %0d TESTS PASSED", tests);
        else
            $display("RESULT: %0d of %0d TESTS FAILED", errors, tests);

        #100;
        $finish;
    end

    // Захист від зависання симуляції
    initial begin
        #200000;
        $display("ERROR: simulation timeout");
        $finish;
    end

endmodule
