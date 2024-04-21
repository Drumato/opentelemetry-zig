const std = @import("std");
pub const IterIDGenerator = struct {
    next_traceid_value: u128,
    next_spanid_value: u64,

    pub fn init() @This() {
        return @This(){
            .next_spanid_value = 0,
            .next_traceid_value = 0,
        };
    }

    pub fn generateTraceID(self: *@This()) u128 {
        const v = self.next_traceid_value;
        self.next_traceid_value += 1;
        return v;
    }
    pub fn generateSpanID(self: *@This()) u64 {
        const v = self.next_spanid_value;
        self.next_spanid_value += 1;
        return v;
    }
};
