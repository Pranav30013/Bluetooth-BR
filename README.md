# Bluetooth Baseband Packet Generator

## Overview
This repository contains a digital hardware implementation of a Bluetooth baseband encoding logic written in Verilog. The project focuses on the accurate generation, formatting, and sequencing of Bluetooth packets, ensuring strict adherence to protocol specifications for physical layer transmission.

## Key Features
* **Protocol-Compliant Packet Formatting:** Generates standard Bluetooth packet structures for baseband transmission, including Access Code, Header, and Payload.
* **Forward Error Correction (FEC):** Implements both 1/3 and 2/3 rate FEC to ensure robust data transmission in noisy RF environments.
* **Error Detection:** Features Header Error Control (HEC) generation to validate packet integrity.
* **Precision Sync Word & Preambles:** Accurately constructs sync words and utilizes Barker sequences essential for receiver alignment.

## Design Decisions & Protocol Alignment
While the BR/EDR bluetooth has many different types of packets, with each packet requiring different payload processing this implementation is intentionally scoped to generate Basic Rate (BR) Synchronous Connection-Oriented (SCO) packets, specifically targeting HV1, HV2, and HV3 packet formats.
A major focus of this implementation was aligning hardware logic with the strict specifications of the Bluetooth wireless protocol:
* **Bit Ordering and Alignment:** During the implementation of the sync word generation, the hardware logic strictly utilizes an **MSB-to-LSB mapping** to ensure the transmitted bitstream accurately aligns with Bluetooth standards. 
* **Verification via Protocol Values:** The bit-alignment strategy and internal XOR logic operations were verified extensively in simulation to ensure the hardware output perfectly matches the expected standard protocol values.


## Packet Structure
The BR/EDR bluetooth packet has three top level fields namely Access Code, Header, Payload each contains different information for the receiver to decode and understand.
<p align="center">
  <img src="https://github.com/user-attachments/assets/30c7791a-f651-4584-a043-838824d97166"  alt="Figure 6.1: General Basic Rate packet format" width="70%">
</p>

* **Access Code:** In the Bluetooth system all transmissions over the physical channel begin with an access code.The access code is 72 or 68 bits and all access codes are derived from the LAP of a device address(either master or slave) or an inquiry address.  

  <p align="center">
  <img src="https://github.com/user-attachments/assets/8abd5a73-6fab-4bb5-abae-a5fe6840844f" alt="Access Code format" width="70%">
  </p>
  
* **Header:** The header contains link control (LC) information and consists of following 6 fields. The total header, including the HEC, consists of 18 bits and is encoded with a rate 1/3 FEC resulting in a 54-bit header.

  <p align="center">
  <img src="https://github.com/user-attachments/assets/6ccf2c3a-a8e9-49ab-a1da-fa71d7a7c2dc" alt="Figure 6.8: Header format" width="70%">
  </p>
  
* **Payload:** In the payload, two fields are distinguished: the synchronous data field and the asynchronous data field. The ACL packets only have the asynchronous data field and the SCO and   eSCO packets only have the synchronous data field with the exception of the DV packets which have both.
  In SCO, which is only supported in Basic Rate mode, the synchronous datafield has a fixed length and consists only of the synchronous data body portion.No payload header is present.
  * **HV1:** The user data is 10 Bytes, with 1/3 FEC the payload becomes 30 Bytes.
  * **HV2:** The user data is 20 Bytes, with 2/3 FEC the payload becomes 30 Bytes.
  * **HV3:** The user data is 30 Bytes and use as is in payload.
  <p align="center">
    <img src="https://github.com/user-attachments/assets/4a4fc4fc-d16f-4b47-ac52-50edd00abc47" width="600">
  <br>
    <img src="https://github.com/user-attachments/assets/459a823c-045c-4761-ab7a-019d733b1014" width="600">
  </p>

  

## Architecture & Module Structure
The design is modularized to reflect the distinct stages of baseband packet generation:

* **`top_mod.v`**: The top-level entity integrating all sub-modules into a cohesive packet generation pipeline and the FSM for each module.
  * **`Acc_gen.v`**: Handles the generation of the Bluetooth Access Code (Preamble, Sync Word, and Trailer).
    * **`Barker_seq_gen.v`**: Generates Barker sequences for synchronization and phase resolution.
    * **`encoding.v`**: Calculates the 34 bit CRC parity for the 30 bit access code information according to the specification.
  * **`header_gen.v`**: Constructs the packet header containing link control information.
      * **`HEC_gen.v`**: Computes the Header Error Control check bits.
  * **`payload_gen.v`**: Manages the formatting and retrieval of the data payload.
       * **`FEC_1_3.v`**: Applies 1/3 rate Forward Error Correction encoding to the header according to the specification for the HV1 packet.
       * **`FEC_2_3.v`**: Applies 2/3 rate Forward Error Correction encoding to the header according to the specification for the HV2 packet.
  * **`reg_bank.v`**: Register bank stores the LAP, UAP, other control signals required for Access code, header and payload generation.
  * **`mem.coe`**: Coefficient file initialized as BRAM containing the raw_payload data and the packet once generated completely.