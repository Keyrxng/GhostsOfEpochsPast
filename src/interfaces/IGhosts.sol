// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
interface IGhosts {    

        function createUser(string memory handle, string[] memory hashes) external returns(uint);
        function startNextRace() external;
        function submitCompletedTask(bytes32 answers, uint perf, string calldata metadata) external;
        function ccGetMetadata(uint256 profileId)
        external
        view
        returns (string memory);
    function ccGetAvatar(uint256 profileId)
        external
        view
        returns (string memory);

    function ccGetSubNFTAddr(uint256 profileId)
        external
        view
        returns (address);

    function ccGetSubURI(uint256 profileId)
        external
        view
        returns (string memory);

    function ccGetEssNFTAddr(uint256 profileId, uint256 essId)
        external
        view
        returns (address);

    function ccGetEssURI(uint256 profileId, uint256 essId)
        external
        view
        returns (string memory);

    function ccSubscribe(uint256[] memory profileIDs) external;

    /**
     * @dev sets the namespace owner of the ProfileNFT to the provided address.
     * @param addr of new namespace owner
     */
    function ccSetNSOwner(address addr) external;

    function ccRegEssence(
        uint256 profileId,
        string calldata name,
        string calldata symbol,
        string calldata essenceURI,
        address essenceMw,
        bool transferable,
        bool deployAtReg
    ) external returns (uint256);

    function ccCollectEss(
        address who,
        uint256 profileId,
        uint256 essenceId
    ) external;

    function ccSetMetadata(uint256 profileId, string calldata metadata)
        external;

    function ccSetSubData(
        uint256 profileId,
        string calldata uri,
        address mw,
        bytes calldata mwData
    ) external;

    function ccSetEssData(
        uint256 profileId,
        uint256 essId,
        string calldata uri,
        address mw,
        bytes calldata mwData
    ) external;

    function ccSetPrimary(uint256 profileId) external;
     /**
     * @notice Check if the profile issued EssenceNFT is collected by me.
     *
     * @param profileId The profile id.
     * @param essenceId The essence id.
     * @param me The address to check.
     * @param _namespace The address of the ProfileNFT
     */
    function isCollectedByMe(
        uint256 profileId,
        uint256 essenceId,
        address me,
        address _namespace
    ) external view returns (bool);

    /**
     * @notice Check if the profile is subscribed by me.
     *
     * @param profileId The profile id.
     * @param me The address to check.
     * @param _namespace The address of the ProfileNFT
     */
    function isSubscribedByMe(uint256 profileId, address me, address _namespace)
        external
        view
        returns (bool);

    }