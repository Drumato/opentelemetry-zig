const std = @import("std");
const os = std.os;
const exporter = @import("otel/exporter.zig");
const trace = @import("otel/trace.zig");
const span = @import("otel/span.zig");
const semconv = @import("otel/semconv.zig");
const sdk = @import("otel/sdk.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .stack_trace_frames = 0 }){};
    defer {
        switch (gpa.deinit()) {
            .ok => {},
            .leak => {},
        }
    }

    const allocator = gpa.allocator();

    var resource_attrs = std.StringHashMap([]const u8).init(allocator);
    defer resource_attrs.deinit();

    try resource_attrs.put(semconv.ServiceNameAttrKey, "otel-zig");

    const resource = sdk.Resource.initWithAttributes(semconv.SchemaURL, resource_attrs);
    const http_exporter = exporter.HTTPExporter.init(allocator);
    const ssp = sdk.SimpleSpanProcessor.init(http_exporter);
    const sdk_tp = sdk.TracerProvider(sdk.SimpleSpanProcessor).init(resource, sdk.SpanProcessor(sdk.SimpleSpanProcessor).init(ssp));
    defer sdk_tp.shutdown();
    const tp = trace.TracerProvider(sdk.TracerProvider(sdk.SimpleSpanProcessor)).init(sdk_tp);

    var tracer = tp.tracer("otel-zig.main");

    for (0..10) |i| {
        const span_context = span.SpanContext.init();
        var span_name: [256]u8 = undefined;
        const result = try std.fmt.bufPrint(&span_name, "loop-{}", .{i});
        const sp = tracer.start(span_context, result);
        defer sp.end();

        try childFn(span_context, &tracer, i);

        std.time.sleep(std.time.ns_per_s);
    }
}

fn childFn(
    ctx: span.SpanContext,
    tracer: *trace.Tracer(sdk.Tracer(sdk.SimpleSpanProcessor)),
    i: usize,
) !void {
    var span_name: [256]u8 = undefined;
    const result = try std.fmt.bufPrint(&span_name, "loop-{}-child", .{i});
    const sp = tracer.start(
        ctx,
        result,
    );
    defer sp.end();
}

test "all" {
    _ = @import("http.zig");
    _ = @import("map.zig");
    _ = @import("otel/protobuf.zig");
}
