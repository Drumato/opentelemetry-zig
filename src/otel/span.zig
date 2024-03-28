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

        pub fn end(self: @This()) void {
            _ = self;
        }
    };
}

pub const SpanContext = struct {
    pub fn init() @This() {
        return @This(){};
    }
};
