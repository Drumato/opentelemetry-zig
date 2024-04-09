const std = @import("std");
const http = @import("../http.zig");
const otelspan = @import("span.zig");
const span = @import("sdk/span.zig");
const protobuf = @import("protobuf.zig");
const resource = @import("sdk/resource.zig");

pub const HTTPExporter = struct {
    client: http.Client,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) @This() {
        const sa = std.posix.getenv("OTEL_EXPORTER_OTLP_ENDPOINT") orelse "http://localhost:8080/";
        return @This(){
            .client = http.Client.init(sa),
            .allocator = allocator,
        };
    }

    pub fn exportSpans(self: @This(), res: resource.Resource, spans: []otelspan.Span(span.RecordingSpan)) !void {
        for (spans) |sp| {
            const proto_sps = try self.allocator.alloc(protobuf.Span, 1);
            proto_sps = protobuf.Span{
                .name = sp.name(),
            };
            const scope = protobuf.Scope{
                .name = "scope1",
                .version = "0.1.0",
                .attributes = undefined,
            };
            const scope_spans = try self.allocator.alloc(protobuf.ScopeSpan, 1);
            scope_spans[0] = protobuf.ScopeSpan{
                .scope = scope,
                .spans = proto_sps,
            };
            const resource_spans = try self.allocator.alloc(protobuf.ResourceSpan, 1);
            resource_spans[0] = protobuf.ResourceSpan{
                .resource = res,
                .scope_spans = scope_spans,
            };
            const t = protobuf.Trace{
                .resource_spans = resource_spans,
            };
            _ = t;
        }
    }
};
