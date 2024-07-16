import serial
import csv

experiment_name = 'debug_exp'
headers = ['timestamp', 'detectors']

# Initialize CSV
csvfile = open(experiment_name+'.csv', 'w', newline='')
writer = csv.writer(csvfile)
writer.writerow(headers)

# Configure for DEBUG
# socat -d -d pty,raw,echo=0 pty,raw,echo=0
serial_port = 'COM10'
num_bytes_record = 19

def byte_arr_to_str(byte_array):
    bin_str = ''
    for byte in byte_array:
        for i in range(8):
            bin_str += str((byte>>(7-i))&1)
    return bin_str

with serial.Serial(serial_port, 19200, timeout=10000, inter_byte_timeout=0.001) as ser:
    while True:
        s = ser.readline(num_bytes_record)
        mask = 0b00001111
        # Check message size to see if it is complete
        if len(s) == num_bytes_record:
            print('New message:')
            timetag_bytes = s[:4]+bytes([s[4]&mask])
            # Timetag in number of clocks since system startup
            timetag = int.from_bytes(timetag_bytes, 'little')

            s_bigendian = bytearray(s)
            s_bigendian.reverse()

            s_bigendian_str = byte_arr_to_str(s_bigendian)
            detectors_str = s_bigendian_str[16:116]

            print(timetag)
            print(detectors_str)
            print(byte_arr_to_str(s))
            print(s_bigendian_str)
            writer.writerow([timetag, detectors_str])
            csvfile.flush()