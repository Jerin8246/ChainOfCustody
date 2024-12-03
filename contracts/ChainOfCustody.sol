// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ChainOfCustody {
    // Enums for evidence states and removal reasons
    enum EvidenceState { INITIAL, CHECKEDIN, CHECKEDOUT, REMOVED }
    enum RemovalReason { NONE, DISPOSED, DESTROYED, RELEASED }

    // Struct to store evidence details
    struct Evidence {
        bytes32 caseId;        // Case UUID (hashed)
        string rawCaseId;      // Original case UUID
        uint256 itemId;        // Evidence item ID
        EvidenceState state;   // Current state
        address owner;         // Current owner
        RemovalReason reason;  // Removal reason if applicable
        string lawfulOwner;    // New owner for RELEASED items
        uint256 timestamp;     // Action timestamp
        bytes32 prevHash;      // Hash of previous block
        bytes32 blockHash;     // Hash of current block
    }

    // Struct for verification errors
    struct VerificationError {
        bool hasError;
        bytes32 badBlock;
        bytes32 parentBlock;
        string errorType;
    }

    // Contract state variables
    address public creator;
    mapping(uint256 => Evidence[]) public evidenceHistory;  // Item ID to history
    mapping(bytes32 => bool) public cases;                  // Track existing cases
    mapping(bytes32 => bool) public blockHashes;           // Track block hashes
    mapping(bytes32 => uint256) public blockParentCount;   // Track number of blocks with same parent
    uint256[] public allItemIds;                           // List of all items
    bytes32[] public allCaseIds;                           // List of all cases
    
    // Events
    event EvidenceAdded(string caseId, uint256 itemId, uint256 timestamp);
    event EvidenceCheckedOut(uint256 itemId, uint256 timestamp);
    event EvidenceCheckedIn(uint256 itemId, uint256 timestamp);
    event EvidenceRemoved(uint256 itemId, RemovalReason reason, uint256 timestamp);

    // Modifiers
    modifier onlyCreator() {
        require(msg.sender == creator, "Only creator can perform this action");
        _;
    }

    modifier evidenceExists(uint256 itemId) {
        require(evidenceHistory[itemId].length > 0, "Evidence does not exist");
        _;
    }

    modifier validCase(bytes32 caseId) {
        require(cases[caseId], "Case does not exist");
        _;
    }

    // Constructor
    constructor() {
        creator = msg.sender;
    }

    // Initialize the blockchain with genesis block
    function initializeBlockchain() public {
        require(allItemIds.length == 0, "Blockchain already initialized");
        
        bytes32 genesisHash = keccak256(abi.encodePacked("GENESIS"));
        bytes32 genesisCaseId = keccak256(abi.encodePacked("GENESIS_CASE"));
        
        Evidence memory genesisBlock = Evidence({
            caseId: genesisCaseId,
            rawCaseId: "GENESIS_CASE",
            itemId: 0,
            state: EvidenceState.INITIAL,
            owner: creator,
            reason: RemovalReason.NONE,
            lawfulOwner: "",
            timestamp: block.timestamp,
            prevHash: bytes32(0),
            blockHash: genesisHash
        });

        evidenceHistory[0].push(genesisBlock);
        cases[genesisCaseId] = true;
        blockHashes[genesisHash] = true;
        allItemIds.push(0);
        allCaseIds.push(genesisCaseId);
    }

    // Add new evidence
    function addEvidence(string memory rawCaseId, uint256[] memory itemIds) public onlyCreator {
        bytes32 caseId = keccak256(abi.encodePacked(rawCaseId));
        
        if (!cases[caseId]) {
            cases[caseId] = true;
            allCaseIds.push(caseId);
        }

        for (uint i = 0; i < itemIds.length; i++) {
            require(evidenceHistory[itemIds[i]].length == 0, "Item already exists");
            
            bytes32 prevHash = evidenceHistory[0][evidenceHistory[0].length - 1].blockHash;
            bytes32 newHash = keccak256(abi.encodePacked(prevHash, itemIds[i], block.timestamp));
            
            blockParentCount[prevHash]++;

            Evidence memory newEvidence = Evidence({
                caseId: caseId,
                rawCaseId: rawCaseId,
                itemId: itemIds[i],
                state: EvidenceState.CHECKEDIN,
                owner: msg.sender,
                reason: RemovalReason.NONE,
                lawfulOwner: "",
                timestamp: block.timestamp,
                prevHash: prevHash,
                blockHash: newHash
            });

            evidenceHistory[itemIds[i]].push(newEvidence);
            blockHashes[newHash] = true;
            allItemIds.push(itemIds[i]);
            
            emit EvidenceAdded(rawCaseId, itemIds[i], block.timestamp);
        }
    }

    // Check out evidence
    function checkout(uint256 itemId) public evidenceExists(itemId) {
        Evidence[] storage history = evidenceHistory[itemId];
        Evidence memory lastEntry = history[history.length - 1];
        
        require(lastEntry.state == EvidenceState.CHECKEDIN, "Item not checked in");
        
        bytes32 newHash = keccak256(abi.encodePacked(
            lastEntry.blockHash,
            itemId,
            block.timestamp,
            EvidenceState.CHECKEDOUT
        ));

        blockParentCount[lastEntry.blockHash]++;

        Evidence memory newEntry = Evidence({
            caseId: lastEntry.caseId,
            rawCaseId: lastEntry.rawCaseId,
            itemId: itemId,
            state: EvidenceState.CHECKEDOUT,
            owner: msg.sender,
            reason: RemovalReason.NONE,
            lawfulOwner: "",
            timestamp: block.timestamp,
            prevHash: lastEntry.blockHash,
            blockHash: newHash
        });

        history.push(newEntry);
        blockHashes[newHash] = true;
        
        emit EvidenceCheckedOut(itemId, block.timestamp);
    }

    // Check in evidence
    function checkin(uint256 itemId) public evidenceExists(itemId) {
        Evidence[] storage history = evidenceHistory[itemId];
        Evidence memory lastEntry = history[history.length - 1];
        
        require(lastEntry.state == EvidenceState.CHECKEDOUT, "Item not checked out");
        
        bytes32 newHash = keccak256(abi.encodePacked(
            lastEntry.blockHash,
            itemId,
            block.timestamp,
            EvidenceState.CHECKEDIN
        ));

        blockParentCount[lastEntry.blockHash]++;

        Evidence memory newEntry = Evidence({
            caseId: lastEntry.caseId,
            rawCaseId: lastEntry.rawCaseId,
            itemId: itemId,
            state: EvidenceState.CHECKEDIN,
            owner: msg.sender,
            reason: RemovalReason.NONE,
            lawfulOwner: "",
            timestamp: block.timestamp,
            prevHash: lastEntry.blockHash,
            blockHash: newHash
        });

        history.push(newEntry);
        blockHashes[newHash] = true;
        
        emit EvidenceCheckedIn(itemId, block.timestamp);
    }

    // Remove evidence
    function removeEvidence(
        uint256 itemId, 
        string memory reason,
        string memory lawfulOwner
    ) public onlyCreator evidenceExists(itemId) {
        Evidence[] storage history = evidenceHistory[itemId];
        Evidence memory lastEntry = history[history.length - 1];
        
        require(lastEntry.state == EvidenceState.CHECKEDIN, "Item not checked in");
        
        RemovalReason removalReason;
        if (keccak256(abi.encodePacked(reason)) == keccak256(abi.encodePacked("DISPOSED"))) {
            removalReason = RemovalReason.DISPOSED;
        } else if (keccak256(abi.encodePacked(reason)) == keccak256(abi.encodePacked("DESTROYED"))) {
            removalReason = RemovalReason.DESTROYED;
        } else if (keccak256(abi.encodePacked(reason)) == keccak256(abi.encodePacked("RELEASED"))) {
            removalReason = RemovalReason.RELEASED;
            require(bytes(lawfulOwner).length > 0, "Lawful owner required for RELEASED items");
        } else {
            revert("Invalid removal reason");
        }

        bytes32 newHash = keccak256(abi.encodePacked(
            lastEntry.blockHash,
            itemId,
            block.timestamp,
            EvidenceState.REMOVED
        ));

        blockParentCount[lastEntry.blockHash]++;

        Evidence memory newEntry = Evidence({
            caseId: lastEntry.caseId,
            rawCaseId: lastEntry.rawCaseId,
            itemId: itemId,
            state: EvidenceState.REMOVED,
            owner: msg.sender,
            reason: removalReason,
            lawfulOwner: lawfulOwner,
            timestamp: block.timestamp,
            prevHash: lastEntry.blockHash,
            blockHash: newHash
        });

        history.push(newEntry);
        blockHashes[newHash] = true;
        
        emit EvidenceRemoved(itemId, removalReason, block.timestamp);
    }

    // Show all cases
    function showCases() public view returns (string[] memory) {
        string[] memory result = new string[](allCaseIds.length);
        for (uint i = 0; i < allCaseIds.length; i++) {
            bytes32 caseId = allCaseIds[i];
            for (uint j = 0; j < allItemIds.length; j++) {
                Evidence[] storage history = evidenceHistory[allItemIds[j]];
                if (history.length > 0 && history[0].caseId == caseId) {
                    result[i] = history[0].rawCaseId;
                    break;
                }
            }
        }
        return result;
    }

    // Show items for a case
    function showItems(string memory rawCaseId) public view returns (uint256[] memory) {
        bytes32 caseId = keccak256(abi.encodePacked(rawCaseId));
        uint256 count = 0;
        
        // Count items in case
        for (uint i = 0; i < allItemIds.length; i++) {
            Evidence[] storage history = evidenceHistory[allItemIds[i]];
            if (history.length > 0 && history[0].caseId == caseId) {
                count++;
            }
        }
        
        // Create result array
        uint256[] memory result = new uint256[](count);
        uint256 index = 0;
        
        // Fill result array
        for (uint i = 0; i < allItemIds.length; i++) {
            Evidence[] storage history = evidenceHistory[allItemIds[i]];
            if (history.length > 0 && history[0].caseId == caseId) {
                result[index] = allItemIds[i];
                index++;
            }
        }
        
        return result;
    }

    // Show history for an item
    function showHistory(uint256 itemId) public view 
        evidenceExists(itemId) 
        returns (Evidence[] memory) 
    {
        return evidenceHistory[itemId];
    }

    // Verify blockchain integrity
    function verify() public view returns (VerificationError memory) {
        VerificationError memory error = VerificationError({
            hasError: false,
            badBlock: bytes32(0),
            parentBlock: bytes32(0),
            errorType: ""
        });

        // Check genesis block
        if (evidenceHistory[0].length == 0) {
            error.hasError = true;
            error.errorType = "No genesis block";
            return error;
        }

        if (evidenceHistory[0][0].state != EvidenceState.INITIAL) {
            error.hasError = true;
            error.errorType = "Invalid genesis block";
            return error;
        }

        // Verify each item's history
        for (uint i = 0; i < allItemIds.length; i++) {
            Evidence[] storage history = evidenceHistory[allItemIds[i]];
            
            for (uint j = 1; j < history.length; j++) {
                // Verify hash chain
                if (history[j].prevHash != history[j-1].blockHash) {
                    error.hasError = true;
                    error.badBlock = history[j].blockHash;
                    error.errorType = "Invalid hash chain";
                    return error;
                }

                // Check for multiple children of same parent
                if (blockParentCount[history[j-1].blockHash] > 1) {
                    error.hasError = true;
                    error.badBlock = history[j].blockHash;
                    error.parentBlock = history[j-1].blockHash;
                    error.errorType = "Multiple children";
                    return error;
                }

                // Verify block hash exists and matches content
                bytes32 calculatedHash = keccak256(abi.encodePacked(
                    history[j].prevHash,
                    history[j].itemId,
                    history[j].timestamp,
                    history[j].state
                ));
                
                if (calculatedHash != history[j].blockHash) {
                    error.hasError = true;
                    error.badBlock = history[j].blockHash;
                    error.errorType = "Content mismatch";
                    return error;
                }

                // Check for actions after removal
                if (j > 0 && history[j-1].state == EvidenceState.REMOVED) {
                    error.hasError = true;
                    error.badBlock = history[j].blockHash;
                    error.errorType = "Post removal action";
                    return error;
                }
            }
        }

        return error;
    }
}