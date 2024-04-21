const resource = @import("resource.zig");
const tracer = @import("tracer.zig");
const SpanProcessor = @import("span_processor.zig").SpanProcessor;
const IDGenerator = @import("../id_generator.zig").IDGenerator;
const IterIDGenerator = @import("../iter_id_generator.zig").IterIDGenerator;

pub fn TracerProvider(comptime SP: type) type {
    return struct {
        res: resource.Resource,
        processor: SpanProcessor(SP),
        id_generator: IDGenerator(IterIDGenerator),

        pub fn init(res: resource.Resource, processor: SpanProcessor(SP)) @This() {
            return @This(){
                .res = res,
                .processor = processor,
                .id_generator = IDGenerator(IterIDGenerator).init(IterIDGenerator.init()),
            };
        }

        pub fn shutdown(_: @This()) void {}
        pub fn TracerType() type {
            return tracer.Tracer(SP);
        }
    };
}
