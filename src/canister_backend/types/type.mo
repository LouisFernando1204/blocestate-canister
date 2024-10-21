import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Nat "mo:base/Nat";

module {
    public type Auction = {
        id : Nat;
        creator : Principal;
        image : Text;
        address : Text;
        province : Text;
        city : Text;
        postalCode : Nat;
        propertyType : Text;
        houseArea : Nat;
        yearBuilt : Nat;
        description : Text;
        startPrice : Nat;
        startAuction : Nat;
        endAuction : Nat;
        certificateNumber : Nat;
        certificate : Text;
    };

    public type Participant = {
        id : Nat;
        user : Principal;
        amount : Nat;
        auctionId : Nat;
    };

    public type FinalBid = {
        id : Nat;
        user : Principal;
        finalPrice : Nat;
        auctionId : Nat;
    };

};
