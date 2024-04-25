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
            self: *@This(),
            allocator: std.mem.Allocator,
            parent_ctx: ?otelspan.SpanContext,
            spanName: []const u8,
        ) !otelspan.Span(span.RecordingSpan(SP)) {
            if (parent_ctx) |pctx| {
                const span_id = self.provider.id_generator.generateSpanID();
                var ctx = otelspan.SpanContext.init(pctx.trace_id, span_id);
                ctx.setParentID(pctx.span_id);
                const s = try span.RecordingSpan(SP).init(allocator, spanName, self, ctx);
                return otelspan.Span(span.RecordingSpan(SP)).init(s);
            } else {
                const trace_id = self.provider.id_generator.generateTraceID();
                const span_id = self.provider.id_generator.generateSpanID();
                const ctx = otelspan.SpanContext.init(trace_id, span_id);
                const s = try span.RecordingSpan(SP).init(allocator, spanName, self, ctx);
                return otelspan.Span(span.RecordingSpan(SP)).init(s);
            }
        }
    };
}
