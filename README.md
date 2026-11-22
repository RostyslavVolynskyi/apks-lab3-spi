# APKS Lab 3: SPI Master (Verilog)

Варіант 6: послідовний інтерфейс SPI, мова Verilog.

Модуль SPI Master (режим 0: CPOL = 0, CPHA = 0, MSB first), розрядність слова 8 біт,
частота SCK = f_clk / (2 * CLK_DIV).

## Структура

| Файл | Призначення |
|---|---|
| `src/spi_tx.v` | передавач: FSM, генерація SCK і CS_N, виведення бітів на MOSI |
| `src/spi_rx.v` | приймач: зчитування MISO по фронту SCK, збирання слова |
| `src/spi_master.v` | верхній модуль (передавач + приймач) |
| `tb/spi_slave_model.v` | поведінкова модель Slave (тільки для симуляції) |
| `tb/tb_spi_master.v` | testbench: тактовий сигнал, скидання, 6 тестових обмінів, перевірка PASS/FAIL |
| `docs/fsm_spi_tx.png` | діаграма станів передавача |
| `run_sim.bat`, `run_wave.bat` | запуск симуляції та перегляд осцилограми |

## Запуск симуляції

У терміналі OSS CAD Suite (`start.bat`) з кореня репозиторію:

```
run_sim.bat
run_wave.bat
```
