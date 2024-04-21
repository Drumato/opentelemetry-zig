pub fn IDGenerator(comptime T: type) type {
    return struct {
        impl: T,

        pub fn init(impl: T) @This() {
            return @This(){
                .impl = impl,
            };
        }

        pub fn generateTraceID(self: *@This()) u128 {
            return self.impl.generateTraceID();
        }

        pub fn generateSpanID(self: *@This()) u64 {
            return self.impl.generateSpanID();
        }
    };
}
