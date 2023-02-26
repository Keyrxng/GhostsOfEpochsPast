pragma solidity ^0.8.9;

import {DataTypes, IProfileNFT} from "./IProfileNFT.sol";

contract GhostsHub {
    /////////////////////////////////
    ///                           ///
    ///          GETTERS          ///
    ///                           ///
    /////////////////////////////////
    IProfileNFT internal constant ProfileNFT =
        IProfileNFT(0x57e12b7a5F38A7F9c23eBD0400e6E53F2a45F271);

    function ccGetMetadata(uint256 profileId)
        internal
        view
        returns (string memory)
    {
        return ProfileNFT.getMetadata(profileId);
    }

    function ccGetAvatar(uint256 profileId)
        internal
        view
        returns (string memory)
    {
        return ProfileNFT.getAvatar(profileId);
    }

    function ccGetSubNFTAddr(uint256 profileId)
        internal
        view
        returns (address)
    {
        return ProfileNFT.getSubscribeNFT(profileId);
    }

    function ccGetSubURI(uint256 profileId)
        internal
        view
        returns (string memory)
    {
        return ProfileNFT.getSubscribeNFTTokenURI(profileId);
    }

    function ccGetEssNFTAddr(uint256 profileId, uint256 essId)
        internal
        view
        returns (address)
    {
        return ProfileNFT.getEssenceNFT(profileId, essId);
    }

    function ccGetEssURI(uint256 profileId, uint256 essId)
        internal
        view
        returns (string memory)
    {
        return ProfileNFT.getEssenceNFTTokenURI(profileId, essId);
    }

    function ccSubscribe(uint256[] memory profileIDs) external {
        _ccSubscribe(profileIDs, msg.sender);
    }

    /**
     * @dev sets the namespace owner of the ProfileNFT to the provided address.
     * @param addr of new namespace owner
     */
    function ccSetNSOwner(address addr) external {
        ProfileNFT.setNamespaceOwner(addr);
    }

    function ccRegEssence(
        uint256 profileId,
        string calldata name,
        string calldata symbol,
        string calldata essenceURI,
        address essenceMw,
        bool transferable,
        bool deployAtReg
    ) external {
        DataTypes.RegisterEssenceParams memory params;

        params.profileId = profileId;
        params.name = name;
        params.symbol = symbol;
        params.essenceTokenURI = essenceURI;
        params.essenceMw = essenceMw;
        params.transferable = transferable;
        params.deployAtRegister = deployAtReg;

        _ccRegEssence(params);
    }

    function ccCollectEss(
        address who,
        uint256 profileId,
        uint256 essenceId
    ) external {
        DataTypes.CollectParams memory params;
        params.collector = who;
        params.profileId = profileId;
        params.essenceId = essenceId;

        _ccCollectEss(params);
    }

    function ccSetMetadata(uint256 profileId, string calldata metadata)
        external
    {
        _ccSetMetadata(profileId, metadata);
    }

    function ccSetSubData(
        uint256 profileId,
        string calldata uri,
        address mw,
        bytes calldata mwData
    ) external {
        _ccSetSubData(profileId, uri, mw, mwData);
    }

    function ccSetEssData(
        uint256 profileId,
        uint256 essId,
        string calldata uri,
        address mw,
        bytes calldata mwData
    ) external {
        _ccSetEssData(profileId, essId, uri, mw, mwData);
    }

    function ccSetPrimary(uint256 profileId) external {
        _ccSetPrimary(profileId);
    }

    function _ccSubscribe(uint256[] memory profileIDs, address who) internal {
        DataTypes.SubscribeParams memory params;
        params.subscriber = who;
        params.profileIds = profileIDs;
        bytes[] memory initData;

        ProfileNFT.subscribe(params, initData, initData);
    }

    function _ccRegEssence(DataTypes.RegisterEssenceParams memory params)
        internal
    {
        ProfileNFT.registerEssence(params, "");
    }

    function _ccCollectEss(DataTypes.CollectParams memory params) internal {
        ProfileNFT.collect(params, "", "");
    }

    function _ccSetMetadata(uint256 profileId, string calldata metadata)
        internal
    {
        ProfileNFT.setMetadata(profileId, metadata);
    }

    function _ccSetSubData(
        uint256 profileId,
        string calldata uri,
        address mw,
        bytes calldata mwData
    ) internal {
        ProfileNFT.setSubscribeData(profileId, uri, mw, mwData);
    }

    function _ccSetEssData(
        uint256 profileId,
        uint256 essId,
        string calldata uri,
        address mw,
        bytes calldata mwData
    ) internal {
        ProfileNFT.setEssenceData(profileId, essId, uri, mw, mwData);
    }

    function _ccSetPrimary(uint256 profileId) internal {
        ProfileNFT.setPrimaryProfile(profileId);
    }
}
