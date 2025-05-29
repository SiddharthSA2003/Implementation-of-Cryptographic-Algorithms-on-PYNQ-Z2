# Implementation-of-Cryptographic-Algorithms-on-PYNQ-Z2
This project implements Elliptic Curve Cryptography (ECC) for public key generation and the ChaCha20 stream cipher for encryption and decryption on the PYNQ-Z2 board.

# Hardware Platform
The design targets the Zynq-7020 SoC on the PYNQ-Z2 board and uses the AXI4-Stream protocol for communication and handshaking between the Processing System (PS) and Programmable Logic (PL).

# Cryptographic Overview
ECC (Elliptic Curve Cryptography) is used to generate public keys from seeded private keys.

A new public key is generated at the start of each session.

ChaCha20 is used for lightweight and secure symmetric encryption and decryption.

# Modes of Operation
The design supports two modes:

Encryption Mode: Activated when the connected switch is LOW.

Decryption Mode: Activated when the switch is HIGH.

This switch must be mapped to a GPIO input on the PYNQ-Z2 board.

# Custom Hardware Modules
256-bit multiplier - for finite field operations

512-bit modulo operator – For modular reduction of large operands.

Modular Inverse Unit – Based on the Binary Extended Euclidean Algorithm (BEEA).

Montgomery Ladder Algorithm – Implements scalar multiplication on Curve25519 using projective coordinates (X, Z) for efficient and secure public key generation.
