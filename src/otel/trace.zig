const span = @import("span.zig");
pub fn TracerProvider(
    comptime TP: type,
) type {
    return struct {
        impl: TP,

        pub fn init(impl: TP) @This() {
            if (@typeInfo(TP) != .Struct) {
                @compileError("TracerProvider instance must be a struct");
            }

            return @This(){
                .impl = impl,
            };
        }

        pub fn tracer(self: @This(), tracerName: []const u8) Tracer(TP.TracerType()) {
            _ = self;
            return Tracer(TP.TracerType()).init(TP.TracerType().init(tracerName));
        }
    };
}

pub fn Tracer(comptime T: type) type {
    return struct {
        impl: T,

        pub fn init(impl: T) @This() {
            if (@typeInfo(T) != .Struct) {
                @compileError("Tracer instance must be a struct");
            }

            return @This(){
                .impl = impl,
            };
        }

        pub fn start(self: @This(), ctx: span.SpanContext, spanName: []const u8) span.Span(T.SpanType()) {
            _ = ctx;
            _ = self;
            const s = T.SpanType().init(spanName);
            return span.Span(T.SpanType()).init(s);
        }
    };
}
