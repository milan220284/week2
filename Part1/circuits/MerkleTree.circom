pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/mux1.circom";

template CheckRoot(n) { // compute the root of a MerkleTree of n Levels 
    signal input leaves[2**n];
    signal output root;
    //[assignment] insert your code here to calculate the Merkle root from 2^n leaves

    signal matrix[n][2**n];
    component poseidons[n-1][2**(n-1)];
    component poseidon = Poseidon(2);

    for (var i = 0; i < 2**n; i++) {
        matrix[0][i] <== leaves[i];
    }

    for (var i = 1; i < n; i++) {
        for (var j = 0; j < 2**(n-i); j++) {
            poseidons[i-1][j] = Poseidon(2);

            poseidons[i-1][j].inputs[0] <== matrix[i-1][2*j];
            poseidons[i-1][j].inputs[1] <== matrix[i-1][2*j+1];

            matrix[i][j] <== poseidons[i-1][j].out;
        }
    }
    
    poseidon.inputs[0] <== matrix[n][0];
    poseidon.inputs[1] <== matrix[n][1];

    root <== poseidon.out;
}

template MerkleTreeInclusionProof(n) {
    signal input leaf;
    signal input path_elements[n];
    signal input path_index[n]; // path index are 0's and 1's indicating whether the current element is on the left or right
    signal output root; // note that this is an OUTPUT signal

    //[assignment] insert your code here to compute the root from a leaf and elements along the path
    //Semaphore code (https://github.com/appliedzkp/semaphore/tree/main/circuits) adjusted for our project 
    component poseidons[n];
    component mux[n]; // selectors for left/right sibiling

    signal hashes[n + 1];
    hashes[0] <== leaf;

    for (var i = 0; i < n; i++) {
        path_index[i] * (1 - path_index[i]) === 0;

        poseidons[i] = Poseidon(2);
        mux[i] = MultiMux1(2);

        mux[i].c[0][0] <== hashes[i];
        mux[i].c[0][1] <== path_elements[i];

        mux[i].c[1][0] <== path_elements[i];
        mux[i].c[1][1] <== hashes[i];

        mux[i].s <== path_index[i];

        poseidons[i].inputs[0] <== mux[i].out[0];
        poseidons[i].inputs[1] <== mux[i].out[1];

        hashes[i + 1] <== poseidons[i].out;
    }

    root <== hashes[n];
}