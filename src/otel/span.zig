pub fn Span(comptime S: type) type {
    return struct {
        impl: S,

        pub fn init(impl: S) @This() {
            if (@typeInfo(S) != .Struct) {
                @compileError("Span instance must be a struct");
            }

            return @This(){
                .impl = impl,
            };
        }

        pub fn name(self: @This()) []const u8 {
            return self.impl.name;
        }

        pub fn startTimeUnixnano(self: @This()) []const u8 {
            return self.impl.startTimeUnixNano();
        }

        pub fn endTimeUnixnano(self: @This()) []const u8 {
            return self.impl.endTimeUnixNano();
        }

        pub fn end(self: @This()) !void {
            return self.impl.end();
        }
    };
}

pub const SpanContext = struct {
    pub fn init() @This() {
        return @This(){};
    }
};
