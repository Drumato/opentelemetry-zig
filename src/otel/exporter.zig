const std = @import("std");
const http = @import("../http.zig");
const otelspan = @import("span.zig");
const span = @import("sdk/span.zig");
const SimpleSpanProcessor = @import("sdk/simple_span_processor.zig").SimpleSpanProcessor;
const protobuf = @import("protobuf.zig");
const resource = @import("sdk/resource.zig");

pub const HTTPExporter = struct {
    client: http.Client,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) @This() {
        return @This(){
            .client = http.Client.init("localhost", 8080),
            .allocator = allocator,
        };
    }

    pub fn exportSpans(self: @This(), res: resource.Resource, spans: []const otelspan.Span(span.RecordingSpan(SimpleSpanProcessor))) !void {
        _ = res;
        for (spans) |sp| {
            const proto_sps = try self.allocator.alloc(protobuf.Span, 1);
            proto_sps[0] = protobuf.Span{
                .trace_id = "",
                .span_id = "",
                .parent_id = "",
                .name = sp.name(),
                .start_time_unixnano = sp.startTimeUnixnano(),
                .end_time_unixnano = sp.endTimeUnixnano(),
                .kind = 0,
                .attributes = undefined,
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
                .resource = protobuf.Resource{
                    .attributes = undefined,
                },
                .scope_spans = scope_spans,
            };
            const t = protobuf.Trace{
                .resource_spans = resource_spans,
            };

            var req = http.Request(protobuf.Trace).init(self.allocator, http.MethodPOST, "/v1/traces");
            try req.addHeader("Content-Type", "application/json");
            req.setBody(t);
            try self.client.send(protobuf.Trace, self.allocator, req);
        }
    }
};
