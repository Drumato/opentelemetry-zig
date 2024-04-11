const OrderedStringMap = @import("map.zig").OrderedStringMap;
const std = @import("std");

pub const Client = struct {
    server_host: []const u8,
    server_port: u16,

    pub fn init(host: []const u8, port: u16) @This() {
        return @This(){
            .server_host = host,
            .server_port = port,
        };
    }

    pub fn send(
        self: @This(),
        comptime T: type,
        allocator: std.mem.Allocator,
        req: Request(T),
    ) !void {
        const server_address = try std.net.Address.parseIp(self.server_host, self.server_port);
        const stream = try std.net.tcpConnectToAddress(server_address);
        defer stream.close();

        var req_buffer = std.ArrayList(u8).init(allocator);
        try req.encode(&req_buffer);
        try stream.writeAll(req_buffer.items);

        const resp_buffer = std.ArrayList(u8).init(allocator);
        _ = try stream.readAll(resp_buffer.items);
    }
};

pub const MethodGET: []const u8 = "GET";
pub const MethodPOST: []const u8 = "POST";

pub fn Request(comptime T: type) type {
    return struct {
        headers: OrderedStringMap([]const u8),
        method: []const u8,
        body: ?T,
        path: []const u8,
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator, m: []const u8, path: []const u8) @This() {
            return @This(){
                .headers = OrderedStringMap([]const u8).init(allocator),
                .method = m,
                .body = null,
                .path = path,
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *@This()) void {
            self.headers.deinit();
        }

        pub fn addHeader(self: *@This(), key: []const u8, value: []const u8) std.mem.Allocator.Error!void {
            return self.headers.put(key, value);
        }
        pub fn setBody(self: *@This(), b: T) void {
            self.body = b;
        }

        pub fn encode(self: @This(), b: *std.ArrayList(u8)) !void {
            try b.appendSlice(self.method);
            try b.append(' ');
            try b.appendSlice(self.path);
            try b.append(' ');
            try b.appendSlice("HTTP/1.1\r\n");

            var headerIter = self.headers.iter();
            while (headerIter.next()) |h| {
                try b.appendSlice(h.key);
                try b.appendSlice(": ");
                try b.appendSlice(h.value);
                try b.appendSlice("\r\n");
            }

            if (self.body) |bd| {
                try b.appendSlice("\r\n");
                const body_out = try std.json.stringifyAlloc(self.allocator, bd, std.json.StringifyOptions{});
                defer self.allocator.free(body_out);
                try b.appendSlice(body_out);
                try b.appendSlice("\r\n");
            }
        }
    };
}

pub const Response = struct {};

test "Request.encode without body" {
    const a = std.testing.allocator;
    var req = Request(u8).init(a, MethodGET, "/foo");
    defer req.deinit();

    try req.addHeader("Host", "www.example.com");
    try req.addHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)");

    var buffer = std.ArrayList(u8).init(a);
    defer buffer.deinit();
    try req.encode(&buffer);

    const request_lines = [_][]const u8{
        "GET /foo HTTP/1.1",
        "Host: www.example.com",
        "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)\r\n",
    };
    const expected = try std.mem.join(a, "\r\n", &request_lines);
    defer a.free(expected);
    try std.testing.expectEqualStrings(expected, buffer.items);
}

test "Request.encode with body" {
    const S = struct {
        foo: []const u8,
    };
    const a = std.testing.allocator;
    var req = Request(S).init(a, MethodGET, "/foo");
    defer req.deinit();
    const s = S{ .foo = "bar" };
    req.setBody(s);

    var buffer = std.ArrayList(u8).init(a);
    defer buffer.deinit();
    try req.encode(&buffer);

    const request_lines = [_][]const u8{
        "GET /foo HTTP/1.1",
        "",
        "{\"foo\":\"bar\"}\r\n",
    };
    const expected = try std.mem.join(a, "\r\n", &request_lines);
    defer a.free(expected);
    try std.testing.expectEqualStrings(expected, buffer.items);
}
