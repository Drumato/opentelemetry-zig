const exporter = @import("../exporter.zig");
const resource = @import("resource.zig");
const otelspan = @import("../span.zig");

pub const SimpleSpanProcessor = struct {
    exporter: exporter.HTTPExporter,

    pub fn init(ex: exporter.HTTPExporter) @This() {
        return @This(){
            .exporter = ex,
        };
    }

    pub fn onEnd(self: @This(), res: *resource.Resource) !void {
        const spans = [_]otelspan.Span(@This()){self};
        try self.exporter.exportSpans(res, spans[0..]);
    }
};
