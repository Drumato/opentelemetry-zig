const std = @import("std");

pub fn OrderedStringMap(comptime V: type) type {
    return struct {
        map: std.StringHashMap(V),
        keys: std.ArrayList([]const u8),

        pub const Iterator = struct {
            pub const Item = struct {
                key: []const u8,
                value: V,
            };
            map: OrderedStringMap(V),
            current: usize,

            pub fn init(m: OrderedStringMap(V)) @This() {
                return @This(){
                    .map = m,
                    .current = 0,
                };
            }

            pub fn next(self: *@This()) ?Item {
                if (self.current >= self.map.keys.items.len) {
                    return null;
                }

                const key = self.map.keys.items[self.current];
                self.current += 1;
                const value = self.map.get(key).?;
                return Item{ .key = key, .value = value };
            }
        };

        pub fn init(allocator: std.mem.Allocator) @This() {
            return @This(){
                .map = std.StringHashMap(V).init(allocator),
                .keys = std.ArrayList([]const u8).init(allocator),
            };
        }

        pub fn deinit(self: *@This()) void {
            self.map.deinit();
            self.keys.deinit();
        }

        pub fn get(self: @This(), key: []const u8) ?V {
            return self.map.get(key);
        }

        pub fn put(self: *@This(), key: []const u8, value: V) !void {
            const isNewKey = self.map.get(key) == null;
            if (isNewKey) {
                try self.keys.append(key);
            }

            return self.map.put(key, value);
        }

        pub fn iter(self: @This()) Iterator {
            return Iterator.init(self);
        }
    };
}

test "OrderedStringMap" {
    const a = std.testing.allocator;
    var m = OrderedStringMap(u8).init(a);
    defer m.deinit();

    try m.put("first", 1);
    try m.put("second", 2);
    try m.put("third", 3);

    try std.testing.expectEqual(1, m.get("first").?);
    try std.testing.expectEqual(2, m.get("second").?);
    try std.testing.expectEqual(3, m.get("third").?);

    var iterator = m.iter();
    try std.testing.expectEqual(1, iterator.next().?.value);
    try std.testing.expectEqual(2, iterator.next().?.value);
    try std.testing.expectEqual(3, iterator.next().?.value);
}
