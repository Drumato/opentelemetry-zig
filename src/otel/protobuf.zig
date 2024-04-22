const std = @import("std");

pub const Trace = struct {
    resourceSpans: []const ResourceSpan,
};

pub const ResourceSpan = struct {
    resource: Resource,
    scopeSpans: []const ScopeSpan,
};

pub const Resource = struct {
    attributes: []const Attribute,
};

pub const Attribute = struct {
    key: []const u8,
    value: AttributeValue,
};

pub const AttributeValue = struct {
    stringValue: ?[]const u8,
};

pub const ScopeSpan = struct {
    scope: Scope,
    spans: []const Span,
};

pub const Scope = struct {
    name: []const u8,
    version: []const u8,
    attributes: []const Attribute,
};

pub const Span = struct {
    traceId: []const u8,
    spanId: []const u8,
    parentSpanId: []const u8,
    name: []const u8,
    startTimeUnixNano: []const u8,
    endTimeUnixNano: []const u8,
    kind: i8,
    attributes: []const Attribute,
};

test "protobuf to json" {
    const a = std.testing.allocator;

    const resource_attrs = [_]Attribute{
        Attribute{
            .key = "resource-attr1",
            .value = AttributeValue{ .string_value = "resource-attr1" },
        },
    };

    const scope_attrs = [_]Attribute{
        Attribute{
            .key = "scope-attr1",
            .value = AttributeValue{ .string_value = "scope-attr1" },
        },
    };
    const span_attrs = [_]Attribute{
        Attribute{
            .key = "span-attr1",
            .value = AttributeValue{ .string_value = "span-attr1" },
        },
    };

    const resource = Resource{
        .attributes = resource_attrs[0..],
    };

    const scope = Scope{
        .name = "scope1",
        .version = "0.1.0",
        .attributes = scope_attrs[0..],
    };

    const spans = [_]Span{
        Span{
            .trace_id = "5B8EFFF798038103D269B633813FC60C",
            .span_id = "EEE19B7EC3C1B174",
            .parent_id = "EEE19B7EC3C1B173",
            .name = "span1",
            .start_time_unixnano = "1544712660000000000",
            .end_time_unixnano = "1544712661000000000",
            .kind = 2,
            .attributes = span_attrs[0..],
        },
    };

    const scope_spans = [_]ScopeSpan{
        ScopeSpan{
            .scope = scope,
            .spans = spans[0..],
        },
    };
    const resource_spans = [_]ResourceSpan{
        ResourceSpan{
            .resource = resource,
            .scope_spans = scope_spans[0..],
        },
    };

    const t = Trace{
        .resource_spans = resource_spans[0..],
    };

    const j = try std.json.stringifyAlloc(a, t, std.json.StringifyOptions{});
    defer a.free(j);
    const ok = try std.json.validate(a, j);
    try std.testing.expect(ok);
}
