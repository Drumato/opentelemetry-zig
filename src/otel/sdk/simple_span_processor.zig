const exporter = @import("../exporter.zig");
const resource = @import("resource.zig");
const otelspan = @import("../span.zig");
const span = @import("span.zig");

pub const SimpleSpanProcessor = struct {
    exporter: exporter.HTTPExporter,

    pub fn init(ex: exporter.HTTPExporter) @This() {
        return @This(){
            .exporter = ex,
        };
    }

    pub fn onEnd(self: @This(), res: resource.Resource, sp: span.RecordingSpan(@This())) !void {
        const spans = [_]otelspan.Span(span.RecordingSpan(@This())){
            otelspan.Span(span.RecordingSpan(@This())).init(sp),
        };
        try self.exporter.exportSpans(res, &spans);
    }
};
