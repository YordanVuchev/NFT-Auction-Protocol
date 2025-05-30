// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

library Time {
    ///@notice The cut-off time in seconds from the start of the day for a day turnover, equivalent to 16 hours (57,600 seconds).
    uint32 constant TURN_OVER_TIME = 57_600;

    ///@notice The total number of seconds in a day.
    uint32 constant SECONDS_PER_DAY = 86_400;

    /**
     * @notice Returns the current block timestamp.
     * @dev This function retrieves the timestamp using assembly for gas efficiency.
     * @return ts The current block timestamp.
     */
    function blockTs() internal view returns (uint32 ts) {
        assembly {
            ts := timestamp()
        }
    }

    /**
     * @notice Calculates the number of weeks passed since a given timestamp.
     * @dev Uses assembly to retrieve the current timestamp and calculates the number of turnover time periods passed.
     * @param t The starting timestamp.
     * @return weeksPassed The number of weeks that have passed since the provided timestamp.
     */
    function weekSince(uint32 t) internal view returns (uint32 weeksPassed) {
        assembly {
            let currentTime := timestamp()
            let timeElapsed := sub(currentTime, t)

            weeksPassed := div(timeElapsed, TURN_OVER_TIME)
        }
    }

    /**
     * @notice Calculates the number of full days between two timestamps.
     * @dev Subtracts the start time from the end time and divides by the seconds per day.
     * @param start The starting timestamp.
     * @param end The ending timestamp.
     * @return daysPassed The number of full days between the two timestamps.
     */
    function dayGap(uint32 start, uint256 end) public pure returns (uint32 daysPassed) {
        assembly {
            daysPassed := div(sub(end, start), SECONDS_PER_DAY)
        }
    }

    /**
     * @notice Calculates the end of the day at 2 PM UTC based on a given timestamp.
     * @dev Adjusts the provided timestamp by subtracting the turnover time, calculates the next day's timestamp at 2 PM UTC.
     * @param t The starting timestamp.
     * @return nextDayStartAtTurnOverTime The timestamp for the next day ending at 2 PM UTC.
     */
    function getDayEnd(uint32 t) public pure returns (uint32 nextDayStartAtTurnOverTime) {
        // Adjust the timestamp to the cutoff time (2 PM UTC)
        uint32 adjustedTime = t - TURN_OVER_TIME;

        // Calculate the number of days since Unix epoch
        uint32 daysSinceEpoch = adjustedTime / SECONDS_PER_DAY;

        // Calculate the start of the next day at 2 PM UTC
        nextDayStartAtTurnOverTime = (daysSinceEpoch + 1) * SECONDS_PER_DAY + TURN_OVER_TIME;
    }
}
