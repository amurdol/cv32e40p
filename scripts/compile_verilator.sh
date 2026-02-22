#!/bin/bash
set -e

# Obtener el directorio raíz del repositorio
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

export DESIGN_RTL_DIR="$ROOT/rtl"
MANIFEST_VERILATOR="$ROOT/cv32e40p_manifest_verilator.f"

echo "--- Preparando manifiesto para Verilator ---"
{
  echo "$ROOT/rtl/include/cv32e40p_pkg.sv"
  echo "$ROOT/rtl/include/cv32e40p_fpu_pkg.sv"
  echo "$ROOT/rtl/include/cv32e40p_apu_core_pkg.sv"
  echo "$ROOT/bhv/include/cv32e40p_tracer_pkg.sv"
  echo "$ROOT/bhv/include/cv32e40p_rvfi_pkg.sv"
  echo "$ROOT/example_tb/core/include/perturbation_pkg.sv"
  # Incluimos el resto de archivos resolviendo la variable de entorno y filtrando los packages ya incluidos
  sed "s:\${DESIGN_RTL_DIR}:$DESIGN_RTL_DIR:g" "$ROOT/cv32e40p_manifest.flist" | grep -v "_pkg.sv"
} > "$MANIFEST_VERILATOR"

echo "--- Iniciando compilación con Verilator ---"
# Usamos nproc para compilar en paralelo si está disponible
JOBS=$(nproc 2>/dev/null || echo 1)

# Nos movemos al root para que las rutas relativas (si quedara alguna) funcionen
cd "$ROOT"

verilator --cc --exe --build -j "$JOBS" \
  --main --timing \
  -f "$MANIFEST_VERILATOR" \
  -I"$ROOT/rtl/include" -I"$ROOT/bhv/include" -I"$ROOT/sva" -I"$ROOT/example_tb/core/include" \
  "$ROOT/example_tb/core/tb_top.sv" \
  "$ROOT/example_tb/core/cv32e40p_tb_subsystem.sv" \
  "$ROOT/example_tb/core/mm_ram.sv" \
  "$ROOT/example_tb/core/dp_ram.sv" \
  "$ROOT/example_tb/core/riscv_gnt_stall.sv" \
  "$ROOT/example_tb/core/riscv_rvalid_stall.sv" \
  "$ROOT/example_tb/core/amo_shim.sv" \
  "$ROOT/example_tb/core/cv32e40p_random_interrupt_generator.sv" \
  --top-module tb_top \
  --Mdir "$ROOT/obj_dir" \
  -Wno-fatal \
  -Wno-UNOPTFLAT -Wno-WIDTH -Wno-CASEINCOMPLETE -Wno-TIMESCALEMOD -Wno-BLKANDNBLK -Wno-PINMISSING -Wno-ALWCOMBORDER -Wno-SYMRSVDWORD -Wno-COMBDLY -Wno-GENUNNAMED -Wno-VARHIDDEN -Wno-DECLFILENAME -Wno-PINCONNECTEMPTY -Wno-REALCVT \
  --trace \
  -DVERILATOR=1

echo ""
echo "--- ¡Compilación completada con éxito! ---"
echo "Ejecutable generado en: $ROOT/obj_dir/Vtb_top"
