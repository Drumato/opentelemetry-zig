const std = @import("std");
const os = std.os;
const trace = @import("otel/trace.zig");
const span = @import("otel/span.zig");
const semconv = @import("otel/semconv.zig");
const sdk = @import("otel/sdk.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .stack_trace_frames = 0 }){};
    const allocator = gpa.allocator();

    var resource_attrs = std.StringHashMap([]const u8).init(allocator);
    defer resource_attrs.deinit();

    try resource_attrs.put(semconv.ServiceNameAttrKey, "otel-zig");

    const resource = sdk.Resource.initWithAttributes(semconv.SchemaURL, resource_attrs);

    const sdk_tp = sdk.TracerProvider.init(resource);
    const tp = trace.TracerProvider(sdk.TracerProvider).init(sdk_tp);

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
    tracer: *trace.Tracer(sdk.Tracer),
    i: usize,
) !void {
    var span_name: [256]u8 = undefined;
    const result = try std.fmt.bufPrint(&span_name, "loop-{}-child", .{i});
    const sp = tracer.start(
        ctx,
        result,
    );
    _ = sp;
}
