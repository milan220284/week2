//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { PoseidonT3 } from "./Poseidon.sol"; //an existing library to perform Poseidon hash on solidity
import "./verifier.sol"; //inherits with the MerkleTreeInclusionProof verifier contract


contract MerkleTree is Verifier {
    uint256[15] public hashes; // the Merkle tree in flattened array form
    uint256 public index = 0; // the current index of the first unfilled leaf
    uint256 public root; // the current Merkle root

    constructor() {
        // [assignment] initialize a Merkle tree of 8 with blank leaves
        uint256[3] memory zeroes;
        // at initializatin all nodes on same level are same, 
        // we precalculate those hashes and then in loops asignes
        zeroes[0] = 0;
        zeroes[1] = PoseidonT3.poseidon([zeroes[0], zeroes[0]]);
        zeroes[2] = PoseidonT3.poseidon([zeroes[1], zeroes[1]]);
        
        for (uint8 i = 0; i < 8; i++) {
            hashes[i] = zeroes[0];
        }

        for (uint8 i = 8; i < 12; i++) {
            hashes[i] = zeroes[1];
        }

        for (uint8 i = 12; i < 14; i++) {
            hashes[i] = zeroes[2];
        }

        hashes[14] = PoseidonT3.poseidon([hashes[12], hashes[13]]);

        root = hashes[14];
    }

    function insertLeaf(uint256 hashedLeaf) public returns (uint256) {
        // [assignment] insert a hashed leaf into the Merkle tree
        hashes[index] = hashedLeaf;

        //recalculate depending node at level 1 - one of nodes: 8,9,10, 11
        if (index % 2 == 0) {
                hashes[8 + index/2] = PoseidonT3.poseidon([hashes[index], hashes[index + 1]]);
            } else {
                hashes[8 + index/2] = PoseidonT3.poseidon([hashes[index - 1], hashes[index]]);
        }

        //recalculate depending node at level 2 depeanding in which sub-tree we are
        if ( (index + 1) % 4 == 0) {
                hashes[12] = PoseidonT3.poseidon([hashes[8], hashes[9]]);
            } else {
                hashes[13] = PoseidonT3.poseidon([hashes[10], hashes[11]]);
        }

        hashes[14] = PoseidonT3.poseidon([hashes[12], hashes[13]]);
        root = hashes[14];

        index++; 

        return root;
    }

    function verify(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[1] memory input
        ) public view returns (bool) {
        // [assignment] verify an inclusion proof and check that the proof root matches current root
        return this.verifyProof(a, b, c, input);
    }
}
