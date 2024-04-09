const Tracer = @import("tracer.zig").Tracer;

pub fn RecordingSpan(comptime SP: type) type {
    return struct {
        name: []const u8,
        tracer: Tracer(SP),

        pub fn init(
            name: []const u8,
            tracer: Tracer(SP),
        ) @This() {
            return @This(){
                .name = name,
                .tracer = tracer,
            };
        }

        pub fn end(self: @This()) void {
            self.tracer.provider.processor.onEnd();
        }
    };
}
