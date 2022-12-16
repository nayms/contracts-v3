// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// solhint-disable quotes

library LibWriteJson {
    function createObject(string memory object) internal pure returns (string memory) {
        return string.concat("{", object, "}");
    }

    function keyObject(string memory key, string memory value) internal pure returns (string memory) {
        return string.concat('"', key, '": ', "{", value, "}");
    }

    function keyValue(string memory key, string memory value) internal pure returns (string memory) {
        return string.concat('"', key, '": ', '"', value, '"');
    }
}
