// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {VmSafe} from "forge-std/Vm.sol";
import {Test, console2} from "forge-std/Test.sol";
import {Counter} from "../src/Counter.sol";

contract CounterTest is Test {
    Counter public counter;
    Counter public counter2;

    function testStateDiffBroadcast() public {
        vm.startStateDiffRecording();
        vm.startBroadcast();

        counter = new Counter();
        counter2 = new Counter();

        counter.setNumber(1);
        counter2.setNumber(2);

        vm.stopBroadcast();
        VmSafe.AccountAccess[] memory accesses = vm.stopAndReturnStateDiff();

        /* First two accesses are for deploying code */
        address counterRecorded = accesses[0].account;
        address counter2Recorded = accesses[1].account;

        /* The two deployments are recorded to have the same address */
        /* This address is different than where the actual deployment happens */
        /* Also, such address has no code */
        assertEq(counterRecorded, counter2Recorded);
        assertTrue(counterRecorded != address(counter));
        assertTrue(counterRecorded != address(counter2));
        assertEq(counterRecorded.code, hex'');

        console2.log("Broadcast", "counter address", address(counter));
        console2.log("Broadcast", "counter2 address", address(counter2));
        console2.log("Broadcast", "counter recorded", counterRecorded);
        console2.log("Broadcast", "counter2 recorded", counter2Recorded);

        /* Last two accesses are for writing to storage */
        address counterWrite = accesses[2].account;
        address counter2Write = accesses[3].account;

        /* Storage is written in the right account */
        assertEq(counterWrite, address(counter));
        assertEq(counter2Write, address(counter2));
    }

    function testStateDiffNoBroadcast() public {
        vm.startStateDiffRecording();

        counter = new Counter();
        counter2 = new Counter();

        counter.setNumber(1);
        counter2.setNumber(2);

        VmSafe.AccountAccess[] memory accesses = vm.stopAndReturnStateDiff();

        /* First two accesses are for deploying code */
        address counterRecorded = accesses[0].account;
        address counter2Recorded = accesses[1].account;

        assertTrue(counterRecorded != counter2Recorded);
        assertEq(counterRecorded,  address(counter));
        assertEq(counter2Recorded, address(counter2));

        console2.log("No Broadcast", "counter address", address(counter));
        console2.log("No Broadcast", "counter2 address", address(counter2));
        console2.log("No Broadcast", "counter recorded", counterRecorded);
        console2.log("No Broadcast", "counter2 recorded", counter2Recorded);

        /* Last two accesses are for writing to storage */
        address counterWrite = accesses[2].account;
        address counter2Write = accesses[3].account;

        /* Storage is written in the right account */
        assertEq(counterWrite, address(counter));
        assertEq(counter2Write, address(counter2));
    }
}
