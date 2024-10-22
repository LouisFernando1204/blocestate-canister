import { test } "mo:test/async";
import Principal "mo:base/Principal";
import Error "mo:base/Error";
import Actor "../src/canister_backend/main";

let alice = Principal.fromText("tw6hs-sxyaa");
let bob = Principal.fromText("wo5qg-ysjiq-5da");

await test(
    "successfully create auction",
    func() : async () {
        let instance = await Actor.Main();
        await instance.createAuction(
            "https://example.com/image.png",
            "123 Main St",
            "Province",
            "City",
            12345,
            "Property Type",
            100,
            2020,
            "Description",
            40,
            20,
            25,
            123456,
            "Certificate",
        );
        let auctions = await instance.getAuctionList();
        assert (1 == auctions.size());
    },
);

await test(
    "successfully retrieve auction list",
    func() : async () {
        let instance = await Actor.Main();
        await instance.createAuction(
            "https://example.com/image.png",
            "123 Main St",
            "Province",
            "City",
            12345,
            "Property Type",
            100,
            2020,
            "Description",
            40,
            20,
            25,
            123456,
            "Certificate",
        );
        let auctions = await instance.getAuctionList();
        assert (auctions.size() == 1);
        assert (auctions[0].address == "123 Main St");
    },
);

await test(
    "successfully bid on auction",
    func() : async () {
        let instance = await Actor.Main();
        await instance.createAuction(
            "https://example.com/image.png",
            "123 Main St",
            "Province",
            "City",
            12345,
            "Property Type",
            100,
            2020,
            "Description",
            40,
            20,
            25,
            123456,
            "Certificate",
        );

        await instance.bidAuction(1, 45);
        let participants = await instance.getAuctionParticipants("123 Main St");
        assert (participants.size() == 1);
    },
);

await test(
    "successfully retrieve all participants",
    func() : async () {
        let instance = await Actor.Main();
        await instance.createAuction(
            "https://example.com/image.png",
            "123 Main St",
            "Province",
            "City",
            12345,
            "Property Type",
            100,
            2020,
            "Description",
            40,
            20,
            25,
            123456,
            "Certificate",
        );
        await instance.bidAuction(1, 45);
        await instance.bidAuction(1, 50);
        let participants = await instance.getAllParticipants();
        assert (participants.size() == 2);
    },
);

await test(
    "successfully check participant verification",
    func() : async () {
        let instance = await Actor.Main();
        await instance.addVerifiedUser("verification_hash");
        let verificationHash = await instance.checkParticipantVerification();
        assert (verificationHash == "verification_hash");
    },
);

await test(
    "successfully create final bid",
    func() : async () {
        let instance = await Actor.Main();
        await instance.createAuction(
            "https://example.com/image.png",
            "123 Main St",
            "Province",
            "City",
            12345,
            "Property Type",
            100,
            2020,
            "Description",
            40,
            20,
            25,
            123456,
            "Certificate",
        );
        await instance.bidAuction(1, 45);
        await instance.decideFinalBid(bob, "123 Main St", 70, 1);
        let finalBids = await instance.getFinalBids();
        assert (finalBids.size() == 1);
        assert (finalBids[0].finalPrice == 70);
    },
);

await test(
    "throw error on invalid auction input",
    func() : async () {
        let instance = await Actor.Main();
        try {
            await instance.createAuction(
                "https://example.com/image.png",
                "",
                "Province",
                "City",
                12345,
                "Property Type",
                100,
                2020,
                "Description",
                40,
                20,
                25,
                123456,
                "Certificate",
            );
        } catch (error) {
            assert (Error.message(error) == "Invalid auction input!");
        };
    },
);

await test(
    "throw error on checking participant verification without verification",
    func() : async () {
        let instance = await Actor.Main();
        try {
            let hash = await instance.checkParticipantVerification();
            assert (hash != "");
        } catch (error) {
            assert (Error.message(error) == "Verification hash not found!");
        };
    },
);

await test(
    "throw error on bid amount less than or equal to start price",
    func() : async () {
        let instance = await Actor.Main();
        await instance.createAuction(
            "https://example.com/image.png",
            "123 Main St",
            "Province",
            "City",
            12345,
            "Property Type",
            100,
            2020,
            "Description",
            40,
            20,
            25,
            123456,
            "Certificate",
        );

        try {
            await instance.bidAuction(1, 40);
        } catch (error) {
            assert (Error.message(error) == "Bid amount must be greater than the starting price!");
        };

        try {
            await instance.bidAuction(1, 30);
        } catch (error) {
            assert (Error.message(error) == "Bid amount must be greater than the starting price!");
        };
    },
);

await test(
    "throw error on bidding for nonexistent auction",
    func() : async () {
        let instance = await Actor.Main();
        try {
            await instance.bidAuction(999, 45);
        } catch (error) {
            assert (Error.message(error) == "Auction not found!");
        };
    },
);

await test(
    "throw error on auction participants not found",
    func() : async () {
        let instance = await Actor.Main();
        let participants = await instance.getAuctionParticipants("Nonexistent Address");
        assert (participants.size() == 0);
    },
);

await test(
    "throw error on invalid final bid input",
    func() : async () {
        let instance = await Actor.Main();
        await instance.createAuction(
            "https://example.com/image.png",
            "123 Main St",
            "Province",
            "City",
            12345,
            "Property Type",
            100,
            2020,
            "Description",
            40,
            20,
            25,
            123456,
            "Certificate",
        );
        await instance.bidAuction(1, 45);
        try {
            await instance.decideFinalBid(bob, "123 Main St", 0, 1);
        } catch (error) {
            assert (Error.message(error) == "Invalid final bid input!");
        };
    },
);

await test(
    "throw error on participant not found during final bid",
    func() : async () {
        let instance = await Actor.Main();
        await instance.createAuction(
            "https://example.com/image.png",
            "123 Main St",
            "Province",
            "City",
            12345,
            "Property Type",
            100,
            2020,
            "Description",
            40,
            20,
            25,
            123456,
            "Certificate",
        );
        await instance.bidAuction(1, 45);
        try {
            await instance.decideFinalBid(alice, "123 Main St", 50, 1);
        } catch (error) {
            assert (Error.message(error) == "Participant not found!");
        };
    },
);
