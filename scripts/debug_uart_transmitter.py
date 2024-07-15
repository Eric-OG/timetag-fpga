import serial

def split_string(string, n):
    # Calculate the length of each part
    part_length = len(string) // n
    # Split the string into parts using slicing
    parts = [string[i * part_length: (i + 1) * part_length] for i in range(n)]
    return parts

# Configure for DEBUG
# socat -d -d pty,raw,echo=0 pty,raw,echo=0
serial_port = '/dev/pts/6'
num_bytes_record = 18

message = '000000000000004000000000000000001356'

bytes_list_raw = split_string(message, num_bytes_record);
# Convert bytes to int format and reverse the order for transmission
bytes_list_int = [int(bytes_list_raw[len(bytes_list_raw)-i-1], 16) for i in range(len(bytes_list_raw))]
bytes_list = bytes(bytes_list_int)

print(bytes_list)

with serial.Serial(serial_port, 19200, timeout=1) as ser:
    ser.write(bytes_list)          # Write the record bytes (same order as the physical implementation)