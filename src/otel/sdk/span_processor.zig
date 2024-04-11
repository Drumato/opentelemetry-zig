const otelspan = @import("../span.zig");
const span = @import("span.zig");
const SimpleSpanProcessor = @import("simple_span_processor.zig").SimpleSpanProcessor;
const resource = @import("resource.zig");

pub fn SpanProcessor(comptime T: type) type {
    return struct {
        impl: T,

        pub fn init(impl: T) @This() {
            if (@typeInfo(T) != .Struct) {
                @compileError("SpanProcessor instance must be a struct");
            }

            return @This(){
                .impl = impl,
            };
        }

        pub fn onEnd(
            self: @This(),
            res: resource.Resource,
            sp: span.RecordingSpan(SimpleSpanProcessor),
        ) !void {
            try self.impl.onEnd(res, sp);
        }

        pub fn shutdown(self: @This()) !void {
            return self.impl.shutdown();
        }
    };
}
