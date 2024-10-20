import { test } "mo:test/async";
import Principal "mo:base/Principal";
import Error "mo:base/Error";
import Actor "../src/canister_backend/main";

let alice = Principal.fromText("ihmrf-7yaaa");
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
            "Description",
            1,
            10,
            123,
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
            "Description",
            1,
            10,
            123,
            "Certificate",
        );
        let auctions = await instance.getAuctionList();
        assert (auctions.size() == 1);
        assert (auctions[0].address == "123 Main St");
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
            "Description",
            1,
            10,
            123,
            "Certificate",
        );
        await instance.bidAuction(0, 100);
        await instance.bidAuction(0, 200);
        let participants = await instance.getAllParticipants();
        assert (participants.size() == 2);
    },
);

await test(
    "successfully retrieve auction participants",
    func() : async () {
        let instance = await Actor.Main();
        await instance.createAuction(
            "https://example.com/image.png",
            "123 Main St",
            "Province",
            "City",
            12345,
            "Property Type",
            "Description",
            1,
            10,
            123,
            "Certificate",
        );
        await instance.bidAuction(0, 100);
        await instance.bidAuction(0, 200);
        let participants = await instance.getAuctionParticipants("123 Main St");
        assert (participants.size() == 2);
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
                "Description",
                1,
                10,
                123,
                "Certificate",
            );
        } catch (error) {
            assert (Error.message(error) == "Invalid auction input!");
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
