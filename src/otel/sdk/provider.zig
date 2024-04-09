const resource = @import("resource.zig");
const tracer = @import("tracer.zig");
const SpanProcessor = @import("span_processor.zig").SpanProcessor;

pub fn TracerProvider(comptime SP: type) type {
    return struct {
        res: resource.Resource,
        processor: SpanProcessor(SP),

        pub fn init(res: resource.Resource, processor: SpanProcessor(SP)) @This() {
            return @This(){
                .res = res,
                .processor = processor,
            };
        }

        pub fn shutdown(_: @This()) void {}
        pub fn TracerType() type {
            return tracer.Tracer(SP);
        }
    };
}
