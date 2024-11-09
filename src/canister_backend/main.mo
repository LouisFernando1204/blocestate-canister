import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Error "mo:base/Error";
import Bool "mo:base/Bool";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Type "types/type";

actor {

  private type Auction = Type.Auction;
  private type Participant = Type.Participant;
  private type FinalBid = Type.FinalBid;

  private var auctions : [Auction] = [];
  private var participants : [Participant] = [];
  private var finalBids : [FinalBid] = [];

  private var verifiedUsers = HashMap.HashMap<Principal, Text>(0, Principal.equal, Principal.hash);
  private var auctionBids = HashMap.HashMap<Text, [Principal]>(0, Text.equal, Text.hash);

  public shared ({ caller }) func createAuction(image : Text, address : Text, province : Text, city : Text, postalCode : Nat, propertyType : Text, houseArea : Nat, yearBuilt : Nat, description : Text, startPrice : Nat, startAuction : Nat, endAuction : Nat, certificateNumber : Nat, certificate : Text) : async () {
    await checkAuctionInput(image, address, province, city, postalCode, propertyType, houseArea, yearBuilt, description, startPrice, startAuction, endAuction, certificateNumber, certificate);
    await createAuctionInput(caller, image, address, province, city, postalCode, propertyType, houseArea, yearBuilt, description, startPrice, startAuction, endAuction, certificateNumber, certificate);
  };

  public shared ({ caller }) func addVerifiedUser(verificationHash : Text) : async () {
    verifiedUsers.put(caller, verificationHash);
  };

  public shared ({ caller }) func bidAuction(auctionId : Nat, bidAmount : Nat) : async () {
    let auction = await checkAuction(auctionId);
    let address = await findAddress(auction);
    await checkParticipantInput(bidAmount, auctionId);
    let participant = await createParticipant(caller, auctionId, bidAmount);
    let updatedParticipants = await checkAndMergeBidders(address, participant);
    auctionBids.put(address, updatedParticipants);
  };

  public shared ({ caller }) func checkParticipantVerification() : async (Text) {
    let verificationOpt = verifiedUsers.get(caller);
    let verificationHash = switch (verificationOpt) {
      case null { throw Error.reject("Verification hash not found!") };
      case (?foundVerificationHash) foundVerificationHash;
    };
    return verificationHash;
  };

  public func decideFinalBid(participant : Principal, address : Text, finalPrice : Nat, auctionId : Nat) : async () {
    let foundParticipant = await checkParticipant(participant, address);
    await checkFinalBidInput(finalPrice, auctionId);
    await createFinalBids(foundParticipant, finalPrice, auctionId);
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

  public query func getFinalBids() : async ([FinalBid]) {
    return finalBids;
  };

  private func checkAuctionInput(image : Text, address : Text, province : Text, city : Text, postalCode : Nat, propertyType : Text, houseArea : Nat, yearBuilt : Nat, description : Text, startPrice : Nat, startAuction : Nat, endAuction : Nat, certificateNumber : Nat, certificate : Text) : async () {
    if (image == "" or address == "" or province == "" or city == "" or postalCode == 0 or propertyType == "" or houseArea == 0 or yearBuilt == 0 or description == "" or startPrice == 0 or startAuction == 0 or endAuction == 0 or certificateNumber == 0 or certificate == "") {
      throw Error.reject("Invalid auction input!");
    };
  };

  private func createAuctionInput(creator : Principal, image : Text, address : Text, province : Text, city : Text, postalCode : Nat, propertyType : Text, houseArea : Nat, yearBuilt : Nat, description : Text, startPrice : Nat, startAuction : Nat, endAuction : Nat, certificateNumber : Nat, certificate : Text) : async () {
    let auction : Auction = {
      id = auctions.size() + 1;
      creator = creator;
      image = image;
      address = address;
      province = province;
      city = city;
      postalCode = postalCode;
      propertyType = propertyType;
      houseArea = houseArea;
      yearBuilt = yearBuilt;
      description = description;
      startPrice = startPrice;
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

  private func checkParticipantInput(bidAmount : Nat, auctionId : Nat) : async () {
    if (bidAmount == 0 or auctionId == 0) {
      throw Error.reject("Invalid participant input!");
    };
    let auction = await checkAuction(auctionId);
    if (bidAmount <= auction.startPrice) {
      throw Error.reject("Bid amount must be greater than the starting price!");
    };
  };

  private func createParticipant(caller : Principal, auctionId : Nat, bidAmount : Nat) : async (Participant) {
    let participant : Participant = {
      id = participants.size() + 1;
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

  private func checkParticipant(participant : Principal, address : Text) : async (Principal) {
    let auctionBidsOpt = auctionBids.get(address);
    let participantsArray = switch (auctionBidsOpt) {
      case null {
        throw Error.reject("No participants found for this auction address!");
      };
      case (?foundParticipants) foundParticipants;
    };
    let participantFoundOpt = Array.find<Principal>(
      participantsArray,
      func(principal : Principal) : Bool {
        principal == participant;
      },
    );
    let foundParticipant = switch (participantFoundOpt) {
      case null { throw Error.reject("Participant not found!") };
      case (?foundPrincipal) foundPrincipal;
    };
    return foundParticipant;
  };

  private func checkFinalBidInput(finalPrice : Nat, auctionId : Nat) : async () {
    if (finalPrice == 0 or auctionId == 0) {
      throw Error.reject("Invalid final bid input!");
    };
  };

  private func createFinalBids(participant : Principal, finalPrice : Nat, auctionId : Nat) : async () {
    let finalBid : FinalBid = {
      id = finalBids.size() + 1;
      user = participant;
      finalPrice = finalPrice;
      auctionId = auctionId;
    };
    finalBids := Array.append(finalBids, [finalBid]);
  };

};
