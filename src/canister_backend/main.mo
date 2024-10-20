import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Error "mo:base/Error";
import Bool "mo:base/Bool";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Type "types/type";

actor AuctionActor {

  private type Auction = Type.Auction;
  private type Participant = Type.Participant;

  private var auctions : [Auction] = [];
  private var participants : [Participant] = [];

  private var verifiedUsers = HashMap.HashMap<Principal, Text>(0, Principal.equal, Principal.hash);
  private var auctionBids = HashMap.HashMap<Text, [Principal]>(0, Text.equal, Text.hash);

  public shared ({ caller }) func createAuction(image : Text, address : Text, province : Text, city : Text, postalCode : Nat, propertyType : Text, description : Text, startAuction : Nat, endAuction : Nat, certificateNumber : Nat, certificate : Text) : async () {
    await checkAuctionInput(image, address, province, city, postalCode, propertyType, description, startAuction, endAuction, certificateNumber, certificate);
    await createAuctionInput(caller, image, address, province, city, postalCode, propertyType, description, startAuction, endAuction, certificateNumber, certificate);
  };

  public shared ({ caller }) func addVerifiedUser(verificationHash : Text) : async () {
    verifiedUsers.put(caller, verificationHash);
  };

  public shared ({ caller }) func bidAuction(auctionId : Nat, bidAmount : Nat) : async () {
    let auction = await checkAuction(auctionId);

    let address = await findAddress(auction);

    let participant = await createParticipant(caller, auctionId, bidAmount);

    let updatedParticipants = await checkAndMergeBidders(address, participant);

    auctionBids.put(address, updatedParticipants);
  };

  public query func getAuctionList() : async ([Auction]) {
    return auctions;
  };

  public query func getAllParticipants() : async ([Participant]) {
    return participants;
  };

  public query func getAuctionParticipants(address : Text) : async ([Principal]) {
    return switch (auctionBids.get(address)) {
      case (?participants) participants;
      case null [];
    };
  };

  private func checkAuctionInput(image : Text, address : Text, province : Text, city : Text, postalCode : Nat, propertyType : Text, description : Text, startAuction : Nat, endAuction : Nat, certificateNumber : Nat, certificate : Text) : async () {
    if (image == "" or address == "" or province == "" or city == "" or postalCode == 0 or propertyType == "" or description == "" or startAuction == 0 or endAuction == 0 or certificateNumber == 0 or certificate == "") {
      throw Error.reject("Invalid auction input!");
    };
  };

  private func createAuctionInput(creator : Principal, image : Text, address : Text, province : Text, city : Text, postalCode : Nat, propertyType : Text, description : Text, startAuction : Nat, endAuction : Nat, certificateNumber : Nat, certificate : Text) : async () {
    let auction : Auction = {
      id = auctions.size();
      creator = creator;
      image = image;
      address = address;
      province = province;
      city = city;
      postalCode = postalCode;
      propertyType = propertyType;
      description = description;
      startAuction = startAuction;
      endAuction = endAuction;
      certificateNumber = certificateNumber;
      certificate = certificate;
    };
    auctions := Array.append(auctions, [auction]);
  };

  private func checkAuction(auctionId : Nat) : async (Auction) {
    let auctionOpt = Array.find<Auction>(
      auctions,
      func(auction : Auction) : Bool {
        auction.id == auctionId;
      },
    );

    let auction = switch (auctionOpt) {
      case null { throw Error.reject("Auction not found!") };
      case (?foundAuction) foundAuction;
    };

    return auction;
  };

  private func findAddress(auction : Auction) : async (Text) {
    return auction.address;
  };

  private func createParticipant(caller : Principal, auctionId : Nat, bidAmount : Nat) : async (Participant) {
    let participant : Participant = {
      id = participants.size();
      user = caller;
      amount = bidAmount;
      auctionId = auctionId;
    };

    participants := Array.append(participants, [participant]);

    return participant;
  };

  private func checkAndMergeBidders(address : Text, newParticipant : Participant) : async [Principal] {
    let existingBids = switch (auctionBids.get(address)) {
      case (?participants) participants;
      case null [];
    };

    let updatedParticipants = Array.append(existingBids, [newParticipant.user]);
    return updatedParticipants;
  };

};
