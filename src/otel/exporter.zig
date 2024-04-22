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
            .client = http.Client.init("127.0.0.1", 4318),
            .allocator = allocator,
        };
    }

    pub fn exportSpans(self: @This(), _: resource.Resource, spans: []const otelspan.Span(*span.RecordingSpan(SimpleSpanProcessor))) !void {
        const attributes = [_]protobuf.Attribute{
            protobuf.Attribute{
                .key = "service.name",
                .value = protobuf.AttributeValue{
                    .stringValue = "otel-zig-example",
                },
            },
        };

        var i: usize = 0;
        const proto_sps = try self.allocator.alloc(protobuf.Span, spans.len);
        defer self.allocator.free(proto_sps);
        for (spans) |sp| {
            proto_sps[i] = protobuf.Span{
                .traceId = try sp.traceID(),
                .spanId = try sp.spanID(),
                .parentSpanId = try sp.parentID(),
                .name = sp.name(),
                .startTimeUnixNano = sp.startTimeUnixnano(),
                .endTimeUnixNano = sp.endTimeUnixnano(),
                .kind = 0,
                .attributes = &attributes,
            };
            i += 1;
        }
        const scope = protobuf.Scope{
            .name = "scope1",
            .version = "0.1.0",
            .attributes = &attributes,
        };
        const scope_spans = try self.allocator.alloc(protobuf.ScopeSpan, 1);
        defer self.allocator.free(scope_spans);
        scope_spans[0] = protobuf.ScopeSpan{
            .scope = scope,
            .spans = proto_sps,
        };
        const resource_spans = try self.allocator.alloc(protobuf.ResourceSpan, 1);
        defer self.allocator.free(resource_spans);
        resource_spans[0] = protobuf.ResourceSpan{
            .resource = protobuf.Resource{
                .attributes = &attributes,
            },
            .scopeSpans = scope_spans,
        };
        const t = protobuf.Trace{
            .resourceSpans = resource_spans,
        };

        var req = http.Request(protobuf.Trace).init(self.allocator, http.MethodPOST, "/v1/traces");
        defer req.deinit();

        try req.addHeader("Content-Type", "application/json");
        try req.addHeader("Host", "127.0.0.1:4318");
        req.setBody(t);

        try self.client.send(protobuf.Trace, self.allocator, &req);
    }
};
