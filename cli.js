#!/usr/bin/env node

const Web3 = require('web3');
const fs = require('fs');
const path = require('path');
const { program } = require('commander');
const { validate: validateUUID } = require('uuid');

// Setup Web3 and Contract
const web3 = new Web3('http://127.0.0.1:7545');
const contractJson = require('./build/contracts/ChainOfCustody.json');
const contract = new web3.eth.Contract(
    contractJson.abi,
    contractJson.networks['5777'].address
);

// Environment variables for passwords
const PASSWORDS = {
    POLICE: process.env.BCHOC_PASSWORD_POLICE || "P80P",
    LAWYER: process.env.BCHOC_PASSWORD_LAWYER || "L76L",
    ANALYST: process.env.BCHOC_PASSWORD_ANALYST || "A65A",
    EXECUTIVE: process.env.BCHOC_PASSWORD_EXECUTIVE || "E69E",
    CREATOR: process.env.BCHOC_PASSWORD_CREATOR || "C67C"
};

// Transaction settings
const txParams = {
    gas: 6000000,
    gasPrice: '20000000000'
};

async function getAccount() {
    const accounts = await web3.eth.getAccounts();
    return accounts[0];
}

// Initialize blockchain
program
    .command('init')
    .description('Initialize the blockchain')
    .action(async () => {
        try {
            const account = await getAccount();
            let initialized = false;

            try {
                const items = await contract.methods.allItemIds(0).call();
                initialized = true;
            } catch (error) {
                initialized = false;
            }

            if (!initialized) {
                await contract.methods.initializeBlockchain().send({ 
                    from: account,
                    ...txParams 
                });
                console.log('> Blockchain file not found. Created INITIAL block.');
            } else {
                console.log('> Blockchain file found with INITIAL block.');
            }
        } catch (error) {
            console.error('Error:', error.message);
            process.exit(1);
        }
    });

// Add new evidence
program
    .command('add')
    .description('Add new evidence')
    .requiredOption('-c, --case <id>', 'Case ID (UUID)')
    .requiredOption('-i, --items <items...>', 'Evidence item IDs')
    .requiredOption('-p, --password <password>', 'Password')
    .action(async (options) => {
        try {
            if (options.password !== PASSWORDS.CREATOR) {
                console.log('> Invalid password');
                process.exit(1);
            }

            if (!validateUUID(options.case)) {
                console.log('> Invalid case ID format');
                process.exit(1);
            }

            const account = await getAccount();
            const itemIds = options.items.map(Number);

            await contract.methods.addEvidence(options.case, itemIds).send({ 
                from: account,
                ...txParams 
            });

            itemIds.forEach(itemId => {
                console.log(`> Added item: ${itemId}`);
                console.log('> Status: CHECKEDIN');
                console.log(`> Time of action: ${new Date().toISOString()}`);
            });
        } catch (error) {
            console.error('Error:', error.message);
            process.exit(1);
        }
    });

// Checkout evidence
program
    .command('checkout')
    .description('Check out evidence')
    .requiredOption('-i, --item <id>', 'Evidence item ID')
    .requiredOption('-p, --password <password>', 'Password')
    .action(async (options) => {
        try {
            if (!Object.values(PASSWORDS).includes(options.password)) {
                console.log('> Invalid password');
                process.exit(1);
            }

            const account = await getAccount();
            const itemId = Number(options.item);

            const history = await contract.methods.showHistory(itemId).call();
            const lastEntry = history[history.length - 1];

            await contract.methods.checkout(itemId).send({ from: account, ...txParams });

            console.log(`> Case: ${lastEntry.rawCaseId}`);
            console.log(`> Checked out item: ${itemId}`);
            console.log('> Status: CHECKEDOUT');
            console.log(`> Time of action: ${new Date().toISOString()}`);
        } catch (error) {
            console.error('Error:', error.message);
            process.exit(1);
        }
    });

// Checkin evidence
program
    .command('checkin')
    .description('Check in evidence')
    .requiredOption('-i, --item <id>', 'Evidence item ID')
    .requiredOption('-p, --password <password>', 'Password')
    .action(async (options) => {
        try {
            if (!Object.values(PASSWORDS).includes(options.password)) {
                console.log('> Invalid password');
                process.exit(1);
            }

            const account = await getAccount();
            const itemId = Number(options.item);

            const history = await contract.methods.showHistory(itemId).call();
            const lastEntry = history[history.length - 1];

            await contract.methods.checkin(itemId).send({ from: account, ...txParams });

            console.log(`> Case: ${lastEntry.rawCaseId}`);
            console.log(`> Checked in item: ${itemId}`);
            console.log('> Status: CHECKEDIN');
            console.log(`> Time of action: ${new Date().toISOString()}`);
        } catch (error) {
            console.error('Error:', error.message);
            process.exit(1);
        }
    });

const show = program.command('show');

// Show all cases
show
    .command('cases')
    .description('Show all cases')
    .action(async () => {
        try {
            const cases = await contract.methods.showCases().call();
            cases.forEach(caseId => {
                if (caseId && caseId !== "GENESIS_CASE") {
                    console.log(`> ${caseId}`);
                }
            });
        } catch (error) {
            console.error('Error:', error.message);
            process.exit(1);
        }
    });

// Show items for a case
show
    .command('items')
    .description('Show items for a case')
    .requiredOption('-c, --case <id>', 'Case ID')
    .action(async (options) => {
        try {
            const items = await contract.methods.showItems(options.case).call();
            items.forEach(item => {
                if (item !== '0') {
                    console.log(`> ${item}`);
                }
            });
        } catch (error) {
            console.error('Error:', error.message);
            process.exit(1);
        }
    });

// Show history for an item
show
    .command('history')
    .description('Show history for an item')
    .requiredOption('-i, --item <id>', 'Evidence item ID')
    .option('-n, --num <number>', 'Number of entries')
    .option('-r, --reverse', 'Reverse order')
    .requiredOption('-p, --password <password>', 'Password')
    .action(async (options) => {
        try {
            if (!Object.values(PASSWORDS).includes(options.password)) {
                console.log('> Invalid password');
                process.exit(1);
            }

            let history = await contract.methods.showHistory(Number(options.item)).call();
            history = history.filter(entry => entry.state !== '0');
            
            if (options.reverse) {
                history = [...history].reverse();
            }
            
            if (options.num) {
                history = history.slice(0, Number(options.num));
            }

            history.forEach(entry => {
                console.log(`> Case: ${entry.rawCaseId}`);
                console.log(`> Item: ${entry.itemId}`);
                console.log(`> Action: ${['INITIAL', 'CHECKEDIN', 'CHECKEDOUT', 'REMOVED'][entry.state]}`);
                console.log(`> Time: ${new Date(Number(entry.timestamp) * 1000).toISOString()}`);
                console.log('');
            });
        } catch (error) {
            console.error('Error:', error.message);
            process.exit(1);
        }
    });

// Remove evidence
program
    .command('remove')
    .description('Remove evidence')
    .requiredOption('-i, --item <id>', 'Evidence item ID')
    .requiredOption('-y, --reason <reason>', 'Reason for removal')
    .option('-o, --owner <owner>', 'New owner for RELEASED items')
    .requiredOption('-p, --password <password>', 'Password')
    .action(async (options) => {
        try {
            if (options.password !== PASSWORDS.CREATOR) {
                console.log('> Invalid password');
                process.exit(1);
            }

            if (!['DISPOSED', 'DESTROYED', 'RELEASED'].includes(options.reason)) {
                console.log('> Invalid reason');
                process.exit(1);
            }

            if (options.reason === 'RELEASED' && !options.owner) {
                console.log('> Owner required for RELEASED items');
                process.exit(1);
            }

            const account = await getAccount();
            await contract.methods.removeEvidence(
                Number(options.item),
                options.reason,
                options.owner || ''
            ).send({ from: account, ...txParams });

            console.log(`> Removed item: ${options.item}`);
            console.log(`> Reason: ${options.reason}`);
            console.log(`> Time of action: ${new Date().toISOString()}`);
        } catch (error) {
            console.error('Error:', error.message);
            process.exit(1);
        }
    });

// Verify blockchain integrity
program
    .command('verify')
    .description('Verify blockchain integrity')
    .action(async () => {
        try {
            const account = await getAccount();
            let allItems = [];
            let itemCount = 0;
            
            // Get all items count
            while (true) {
                try {
                    const item = await contract.methods.allItemIds(itemCount).call();
                    allItems.push(item);
                    itemCount++;
                } catch (error) {
                    break;
                }
            }
            
            console.log(`> Transactions in blockchain: ${itemCount}`);
            
            try {
                const verificationResult = await contract.methods.verify().call();
                
                if (!verificationResult.hasError) {
                    console.log('> State of blockchain: CLEAN');
                } else {
                    console.log('> State of blockchain: ERROR');
                    
                    if (verificationResult.badBlock !== '0x0000000000000000000000000000000000000000000000000000000000000000') {
                        console.log(`> Bad block:\n${verificationResult.badBlock}`);
                    }
                    
                    if (verificationResult.errorType === "Invalid hash chain") {
                        console.log('> Parent block: NOT FOUND');
                    } 
                    else if (verificationResult.errorType === "Multiple children") {
                        console.log(`> Parent block:\n${verificationResult.parentBlock}`);
                        console.log('> Two blocks were found with the same parent.');
                    }
                    else if (verificationResult.errorType === "Content mismatch") {
                        console.log('> Block contents do not match block checksum.');
                    }
                    else if (verificationResult.errorType === "Post removal action") {
                        console.log('> Item checked out or checked in after removal from chain.');
                    }
                }
            } catch (error) {
                console.log('> State of blockchain: ERROR');
                if (error.message.includes('Invalid number of parameters')) {
                    console.log('> Error accessing blockchain data');
                } else {
                    console.log('> Blockchain verification failed');
                }
            }
        } catch (error) {
            console.error('Error:', error.message);
            process.exit(1);
        }
    });

program.parse(process.argv);