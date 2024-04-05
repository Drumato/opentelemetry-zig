const otelspan = @import("../span.zig");
const span = @import("span.zig");

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

        pub fn exportSpans(self: @This(), spans: []otelspan.Span(span.RecordingSpan)) !void {
            _ = spans;
            return self.impl.exportSpans();
        }

        pub fn shutdown(self: @This()) !void {
            return self.impl.shutdown();
        }
    };
}
