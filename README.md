# Blockchain Chain of Custody System

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

4. Compile Smart Contracts:
    - truffle compile

5. Deploy Smart Contracts:
    -  truffle migrate --reset

6. Verifications
    - Confirm Truffle installation
        npx truffle version
    - Ensure Ganache is running and connected.
