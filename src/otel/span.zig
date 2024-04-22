pub fn Span(comptime S: type) type {
    return struct {
        impl: S,

        pub fn init(impl: S) @This() {
            return @This(){
                .impl = impl,
            };
        }

        pub fn name(self: @This()) []const u8 {
            return self.impl.name;
        }

        pub fn startTimeUnixnano(self: @This()) []const u8 {
            return self.impl.startTimeUnixnano();
        }

        pub fn endTimeUnixnano(self: @This()) []const u8 {
            return self.impl.endTimeUnixnano();
        }

        pub fn end(self: *@This()) !void {
            return self.impl.end();
        }
        pub fn spanContext(self: @This()) SpanContext {
            return self.impl.spanContext();
        }

        pub fn traceID(self: @This()) ![]const u8 {
            return self.impl.traceIDString();
        }

        pub fn spanID(self: @This()) ![]const u8 {
            return self.impl.spanIDString();
        }

        pub fn parentID(self: @This()) ![]const u8 {
            return self.impl.parentIDString();
        }
    };
}

pub const SpanContext = struct {
    trace_id: u128,
    span_id: u64,
    parent_id: u64,
    pub fn init(trace_id: u128, span_id: u64) @This() {
        return @This(){
            .trace_id = trace_id,
            .span_id = span_id,
            .parent_id = 0,
        };
    }

    pub fn setParentID(self: *@This(), parent_id: u64) void {
        self.parent_id = parent_id;
    }
};
