const span = @import("span.zig");
pub const Tracer = struct {
    name: []const u8,

    pub fn init(name: []const u8) @This() {
        return @This(){
            .name = name,
        };
    }

    pub fn SpanType() type {
        return span.RecordingSpan;
    }
};
