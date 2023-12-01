pragma solidity ^0.8.9;

import {DataTypes, IProfileNFT} from "../interfaces/IProfileNFT.sol";
import {GhostsLib} from "./GhostsLib.sol";
import "forge-std/Test.sol";

library ComHandler {
    using GhostsLib for *;

    IProfileNFT internal constant ccProfileNFT =
        IProfileNFT(0x57e12b7a5F38A7F9c23eBD0400e6E53F2a45F271);


    function followUser(
        mapping(uint=>uint[]) storage IdToFollowers,
        mapping(uint=>uint[]) storage idToFollowing,
        mapping(uint=>GhostsLib.UserFeats) storage getUser,
        mapping(address=>GhostsLib.User) storage addrToUser,
        uint32 idToFollow,
        address addressToFollow
    ) external returns(bool){
        if(msg.sender == addressToFollow){
            revert GhostsLib.NoSuccess();
        }
        GhostsLib.User memory caller = addrToUser[msg.sender];
        GhostsLib.User memory beingFollowed = addrToUser[addressToFollow];
        GhostsLib.UserFeats storage callerF = getUser[caller.ghostsID];
        GhostsLib.UserFeats storage bFF = getUser[beingFollowed.ghostsID];
        uint16 idToBeFollow = uint16(beingFollowed.ccID);        
        callerF.following.push(uint16(idToFollow));
        bFF.followers.push(idToBeFollow);
        callerF.followCount++;
        bFF.followerCount++;
        return true;
    }

    function unfollowUser(
        mapping(uint=>uint[]) storage IdToFollowers,
        mapping(uint=>uint[]) storage idToFollowing,
        mapping(uint=>GhostsLib.UserFeats) storage getUser,
        mapping(address=>GhostsLib.User) storage addrToUser,
        uint32 idToUnfollow,
        address addrToUnfollow
    ) external returns(bool) {
        if(msg.sender == addrToUnfollow){
            revert GhostsLib.NoSuccess();
        }
        GhostsLib.User memory caller = addrToUser[msg.sender];
        GhostsLib.User memory beingFollowed = addrToUser[addrToUnfollow];
        GhostsLib.UserFeats storage callerF = getUser[caller.ghostsID];
        GhostsLib.UserFeats storage bFF = getUser[beingFollowed.ghostsID];
        uint16 followeeNum = uint16(beingFollowed.ccID);
        uint16 idToBeFollow = uint16(beingFollowed.ccID);
    }


}