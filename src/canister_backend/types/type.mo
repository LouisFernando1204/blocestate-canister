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
        description : Text;
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
};
