const std = @import("std");
const http = @import("../http.zig");

pub const HTTPExporter = struct {
    client: http.Client,

    pub fn init() @This() {
        const sa = std.posix.getenv("OTEL_EXPORTER_OTLP_ENDPOINT") orelse "http://localhost:8080/";
        return @This(){
            .client = http.Client.init(sa),
        };
    }
};
