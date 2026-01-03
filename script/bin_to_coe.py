import argparse

def bin_to_coe(input_file, output_file):
    with open(input_file, 'rb') as bin_file, open(output_file, 'w') as coe_file:
        coe_file.write("memory_initialization_radix=16;\n")
        coe_file.write("memory_initialization_vector=\n")
        byte = bin_file.read(1)
        count = 0
        while byte:
            coe_file.write(f'{int.from_bytes(byte, "big"):02X}')
            count += 1
            byte = bin_file.read(1)
            if byte:
                coe_file.write(',\n')
            elif not byte:
                coe_file.write(';\n')

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Convert a binary file to COE format.')
    parser.add_argument('--input-file', type=str, help='Path to the input binary file')
    parser.add_argument('--output-file', type=str, help='Path to the output COE file')
    args = parser.parse_args()

    input_file = args.input_file
    output_file = args.output_file

    bin_to_coe(input_file, output_file)
