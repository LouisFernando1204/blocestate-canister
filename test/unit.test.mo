import {test} "mo:test/async";

await test("successfully", func() : async() {
    assert(1 == 1);
});
