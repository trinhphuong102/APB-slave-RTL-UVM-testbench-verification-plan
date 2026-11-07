import os
import subprocess
import shutil
import sys
import argparse

# Tự động nhận diện thư mục cài đặt QuestaSim trên Linux & cấu hình tỉ lệ hiển thị
os.environ["QT_SCALE_FACTOR"] = "2.0"
os.environ["QT_AUTO_SCREEN_SCALE_FACTOR"] = "0"
os.environ["QT_SCALE_FACTOR_ROUNDING_POLICY"] = "PassThrough"
os.environ["QT_FONT_DPI"] = "140"

QUESTA_HOME = os.environ.get("QUESTASIM_HOME", os.path.expanduser("~/altera_pro/26.1.1/questa_fse"))
QUESTA_BIN = os.path.join(QUESTA_HOME, "bin") if os.path.isdir(os.path.join(QUESTA_HOME, "bin")) else QUESTA_HOME

VLIB = shutil.which("vlib") or os.path.join(QUESTA_BIN, "vlib")
VLOG = shutil.which("vlog") or os.path.join(QUESTA_BIN, "vlog")
VSIM = shutil.which("vsim") or os.path.join(QUESTA_BIN, "vsim")

COMPILE_FILES = [
    "../rtl/async_apb_slave.sv",
    "../tb/apb_if.sv",
    "../tb/apb_pkg.sv",
    "../tb/apb_tb_top.sv" 
]

def run_command(cmd):
    print(f"\n[EXEC] {cmd}")
    result = subprocess.run(cmd, shell=True)
    
    if result.returncode != 0:
        print(f"\n[ERROR] Command failed: {cmd}")
        sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description="Python script to run APB Slave UVM on QuestaSim")
    parser.add_argument('-gui', action='store_true', help="Open QuestaSim GUI for waveform debugging")
    args = parser.parse_args()

    print("==================================================")
    print("       STARTING COMPILATION AND SIMULATION        ")
    print("==================================================")

    if os.path.exists("work"):
        print("[CLEAN] Removing old 'work' library...")
        shutil.rmtree("work")
    
    run_command(f'"{VLIB}" work')

    for file in COMPILE_FILES:
        run_command(f'"{VLOG}" -sv +incdir+../tb {file}')

    print("\n[INFO] Compilation successful! Starting simulation...\n")

    if args.gui:
        with open("wave.do", "w") as f:
            f.write("configure wave -signalnamewidth 1\n")
            f.write("configure wave -namecolwidth 220\n")
            f.write("configure wave -valuecolwidth 120\n")
            f.write("configure wave -justifyvalue left\n")
            f.write("add wave -position insertpoint sim:/tb_top/vif/*\n")
            f.write("run -all\n")
            f.write("wave zoom full\n")
        
        vsim_cmd = f'"{VSIM}" -gui -onfinish stop -nocvg -voptargs=+acc -uvmcontrol=all work.tb_top -do wave.do'
        run_command(vsim_cmd)
    else:
        vsim_cmd = f'"{VSIM}" -c -nocvg -voptargs=+acc work.tb_top -do "run -all; quit"'
        run_command(vsim_cmd)

    print("\n==================================================")
    print("               SIMULATION COMPLETED               ")
    print("==================================================")     

if __name__ == "__main__":
    main()
