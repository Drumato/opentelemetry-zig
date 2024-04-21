const std = @import("std");
const span = @import("span.zig");
const otelspan = @import("../span.zig");
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

        pub fn start(
            self: @This(),
            allocator: std.mem.Allocator,
            ctx: otelspan.SpanContext,
            spanName: []const u8,
        ) !otelspan.Span(span.RecordingSpan(SP)) {
            const s = try span.RecordingSpan(SP).init(allocator, spanName, self, ctx);
            return otelspan.Span(span.RecordingSpan(SP)).init(s);
        }
    };
}
