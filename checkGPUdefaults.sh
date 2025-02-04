echo -e "\n\n"
echo "----------------------------------------------------"
set +m > /dev/null 2>&1  # Suppress job control messages immediately
sudo nvidia-smi -pm 1 > /dev/null

# Loop through each GPU to test and report individually
for gpu_id in $(nvidia-smi --query-gpu=index --format=csv,noheader); do
  gpu_bus_id=$(nvidia-smi --id=$gpu_id --query-gpu=index,pci.bus_id --format=csv,noheader | cut -d',' -f2)
  
  echo -e "\nTesting GPU $gpu_id -- $gpu_bus_id"
  echo -e "                                Default      Custom"
  echo "----------------------------------------------------"
  
  # Run load test for this GPU
  sudo nvidia-smi --id=$gpu_id -lgc 10 > /dev/null 2>&1
  
  if nvidia-smi --id=$gpu_id -q -d CLOCK >/dev/null 2>&1; then
    default_graphics=$(nvidia-smi --id=$gpu_id -q -d CLOCK | grep -A 2 "Default Applications Clocks" | grep "Graphics" | awk '{if (NR==1) print $3 " MHz"}')
    default_memory=$(nvidia-smi --id=$gpu_id -q -d CLOCK | grep -A 2 "Default Applications Clocks" | grep "Memory" | awk '{if (NR==1) print $3 " MHz"}')
    
    custom_graphics=$(nvidia-smi --id=$gpu_id -q -d CLOCK | grep -A 2 "Applications Clocks" | grep "Graphics" | awk '{if (NR==1) print $3 " MHz"}')
    custom_memory=$(nvidia-smi --id=$gpu_id -q -d CLOCK | grep -A 2 "Applications Clocks" | grep "Memory" | awk '{if (NR==1) print $3 " MHz"}')

    echo -e "Applications Clocks Graphics....${default_graphics:-N/A}      ${custom_graphics:-N/A}"
    echo -e "Applications Clocks Memory......${default_memory:-N/A}      ${custom_memory:-N/A}"
    
    power_limit=$(nvidia-smi --id=$gpu_id -q -d POWER | grep "Current Power Limit" | awk '{if (NR==1) print $5 " W"}')
    echo -e "Power Limit.....................${power_limit:-N/A}      ${power_limit:-N/A}"
    
    temp_limit=$(nvidia-smi --id=$gpu_id -q -d TEMPERATURE | grep "GPU Shutdown Temp" | awk '{if (NR==1) print $5 " °C"}')
    echo -e "Temperature Limit...............${temp_limit:-N/A}      ${temp_limit:-N/A}"
    
    # Fan Speed
    fan_speed=$(nvidia-smi --id=$gpu_id -q -d FAN | grep "Fan Speed" | awk '{if (NR==1) print $4 "%"}')
    echo -e "Fan Speed.......................${fan_speed:-N/A}      ${fan_speed:-N/A}"
    
    # Voltage Offset
    voltage_offset=$(nvidia-smi --id=$gpu_id -q -d VOLTAGE | grep "GPU Voltage Offset" | awk '{if (NR==1) print $5 " mV"}')
    echo -e "Voltage Offset..................${voltage_offset:-0 mV}      ${voltage_offset:-0 mV}"
  else
    echo -e "GPU $gpu_id: Error querying GPU status."
  fi
done

echo -e "\n"
set -m > /dev/null 2>&1  # Restore job control messages

echo -e "Every NVIDIA GPU model reports differently. Your GPU model may report multiple N/A"
