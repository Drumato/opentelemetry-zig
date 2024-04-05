const exporter = @import("../exporter.zig");

pub const SimpleSpanProcessor = struct {
    exporter: exporter.HTTPExporter,
    pub fn init(ex: exporter.HTTPExporter) @This() {
        return @This(){
            .exporter = ex,
        };
    }
};
