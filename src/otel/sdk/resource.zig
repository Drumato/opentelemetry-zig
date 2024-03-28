const std = @import("std");

pub const Resource = struct {
    schema_url: []const u8,
    attrs: std.StringHashMap([]const u8),

    pub fn initWithAttributes(
        schema_url: []const u8,
        attrs: std.StringHashMap([]const u8),
    ) @This() {
        return @This(){
            .schema_url = schema_url,
            .attrs = attrs,
        };
    }
};
