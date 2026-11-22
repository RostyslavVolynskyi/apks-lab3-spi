@echo off
rem Симуляція SPI Master (Icarus Verilog). Запускати з термінала OSS CAD Suite (start.bat)
rem з кореня репозиторію:  run_sim.bat
if not exist sim mkdir sim
if not exist build mkdir build
iverilog -g2005 -Wall -o build\spi_sim.vvp src\spi_tx.v src\spi_rx.v src\spi_master.v tb\spi_slave_model.v tb\tb_spi_master.v
if errorlevel 1 (
    echo Compilation FAILED
    exit /b 1
)
vvp build\spi_sim.vvp > sim\sim_log.txt
type sim\sim_log.txt
