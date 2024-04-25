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
    var sdk_tp = sdk.TracerProvider(sdk.SimpleSpanProcessor).init(resource, sdk.SpanProcessor(sdk.SimpleSpanProcessor).init(ssp));
    defer sdk_tp.shutdown();
    const tp = trace.TracerProvider(sdk.TracerProvider(sdk.SimpleSpanProcessor)).init(sdk_tp);

    var tracer = tp.tracer("otel-zig.main");

    for (0..10) |i| {
        std.debug.print("loop {}\n", .{i});
        const span_name = try std.fmt.allocPrint(allocator, "loop-{}", .{i});
        defer allocator.free(span_name);
        var sp = try tracer.start(allocator, null, span_name);

        try childFn(allocator, sp.context(), &tracer, i);

        std.time.sleep(2 * std.time.ns_per_s);
        try sp.end();
    }
}

fn childFn(
    allocator: std.mem.Allocator,
    ctx: span.SpanContext,
    tracer: *trace.Tracer(sdk.Tracer(sdk.SimpleSpanProcessor)),
    i: usize,
) !void {
    const span_name = try std.fmt.allocPrint(allocator, "loop-{}-child", .{i});
    defer allocator.free(span_name);
    var sp = try tracer.start(
        allocator,
        ctx,
        span_name,
    );

    std.time.sleep(1 * std.time.ns_per_s);
    try sp.end();
}

test "all" {
    _ = @import("http.zig");
    _ = @import("map.zig");
    _ = @import("otel/protobuf.zig");
}
