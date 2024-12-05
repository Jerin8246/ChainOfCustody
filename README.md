# Blockchain Chain of Custody System

## Group 12

## Members
- Rajanandini Bandi
- Vishnu Nandam
- Shray Soorma
- Brennan Chan
- Jerin Joseph

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Technologies Used](#technologies-used)
- [Setup and Installation](#setup-and-installation)
- [Usage](#usage)
- [Project Details](#project-details)
- [Contributors](#contributors)

## Overview

This project implements a **Blockchain-based Chain of Custody System** designed to preserve the integrity and security of digital evidence. Using blockchain, it ensures a tamper-proof, chronological record of all interactions with evidence, which is crucial in forensic investigations. The project is implemented using **Solidity**, **JavaScript**, and the Ethereum blockchain.

## Features

- **Immutability**: All transactions are stored permanently in the blockchain.
- **Role-Based Access**: Secure access for police, analysts, lawyers, and executives.
- **Evidence Tracking**: Commands for adding, checking in/out, and removing evidence.
- **Blockchain Integrity Verification**: Validate the hash chain for tamper detection.
- **Command-Line Interface (CLI)**: Intuitive commands for interacting with the system.

## Technologies Used

- **Programming Languages**: JavaScript, Solidity
- **Blockchain Framework**: Ethereum
- **Development Tools**: Truffle, Ganache
- **Libraries**:
  - `web3.js` for blockchain interaction
  - `commander.js` for CLI management
  - `dotenv` for environment variable management

## Setup and Installation

### Prerequisites

- Operating System: macOS (or Linux/Windows with adaptations)
- Software:
  - Node.js (version `20.18.1`)
  - npm (Node Package Manager)
  - Truffle (for smart contract management)
  - Ganache (for local blockchain simulation)

### Installation Steps

1. **Clone the Repository**:
   ```bash
   git clone <repository-link>
   cd ChainOfCustody

2. **Install Dependencies**:
    - Install Node.js version 20.18.1
        - nvm install 20.18.1
        - nvm use 20
    - Install project dependencies:
        - npm install
    - Install Truffle globally:
        - npm install -g truffle

3. **Set Up Ganache:**:
    - Download and install Ganache from the official site: https://archive.trufflesuite.com/ganache/
    - Start Ganache and ensure the RPC Server is http://127.0.0.1:7545 and Network ID is 5777.

4. **Compile Smart Contracts**:
    - truffle compile

5. **Deploy Smart Contracts**:
    -  truffle migrate --reset

6. **Verifications**:
    - Confirm Truffle installation
        npx truffle version
    - Ensure Ganache is running and connected.

## Usage

### Examples of Commands

1. **Initialize Blockchain:**
    - node cli.js init

2. **Add Evidence**
    - node cli.js add -c c84e339e-5c0f-4f4d-84c5-bb79a3c1d2a2 -i 1004820154 -p C67C

3. **Show History of an Item:**
    - node cli.js show history -i 1004820154 -p A65A

4. **Check Out Evidence:**
    - node cli.js checkout -i 1004820154 -p A65A

5. **Check In Evidence:**
    - node cli.js checkin -i 1004820154 -p A65A

6. **Verify Blockchain Integrity:**
    - node cli.js verify

7. **Show All Cases:**
    - node cli.js show cases

8. **Add Multiple Items to a Case:**
    - node cli.js add -c c84e339e-5c0f-4f4d-84c5-bb79a3c1d2a2 -i 1004820155 1004820156 -p C67C

9. **Remove Evidence:**
    - node cli.js remove -i 1004820154 -y DISPOSED -p C67C

10. **To checkout more commands to perform the full functionaliy of the program click the link below
    - https://docs.google.com/document/d/1Y_9ZyGNDw3N-qCHLIq4i3fSF70D_3KzVWxXe6HTH-oE/edit?tab=t.0

## Project Details

### Blockchain Design

- **Smart Contracts**: Written in Solidity and deployed on the Ethereum blockchain.
- **Data Storage**: Immutable evidence blocks with cryptographic linkage.

### CLI Design

- **Interface**: Built using `commander.js`.
- **Interaction**: Provides structured commands for evidence management.

## Contributors

**Group 12**:
- Rajanandini Bandi
- Vishnu Nandam
- Shray Soorma
- Brennan Chan
- Jerin Joseph
