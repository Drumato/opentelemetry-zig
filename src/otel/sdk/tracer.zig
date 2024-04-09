const span = @import("span.zig");
const TracerProvider = @import("provider.zig").TracerProvider;

pub fn Tracer(comptime SP: type) type {
    return struct {
        name: []const u8,
        provider: TracerProvider(SP),

        pub fn init(
            name: []const u8,
            provider: TracerProvider(SP),
        ) @This() {
            return @This(){
                .name = name,
                .provider = provider,
            };
        }

        pub fn SpanType() type {
            return span.RecordingSpan(SP);
        }
    };
}
