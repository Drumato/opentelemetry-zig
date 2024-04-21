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
        req: *Request(T),
    ) !void {
        const server_address = try std.net.Address.parseIp(self.server_host, self.server_port);
        const stream = try std.net.tcpConnectToAddress(server_address);
        defer stream.close();

        var req_buffer = std.ArrayList(u8).init(allocator);
        defer req_buffer.deinit();
        try req.encode(&req_buffer);
        std.debug.print("request: {s}\n", .{req_buffer.items});
        try stream.writeAll(req_buffer.items);

        const resp_buffer = try allocator.alloc(u8, 4096);
        _ = try stream.readAll(resp_buffer);

        std.debug.print("received response: {s}\n", .{resp_buffer});

        var resp = try Response.decode(allocator, resp_buffer);
        defer resp.deinit();

        std.debug.print("received response: {s} {} {s}\n", .{ resp.http_version, resp.status_code, resp.reason_phrase });
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

        pub fn encode(self: *@This(), b: *std.ArrayList(u8)) !void {
            try b.appendSlice(self.method);
            try b.append(' ');
            try b.appendSlice(self.path);
            try b.append(' ');
            try b.appendSlice("HTTP/1.1\r\n");

            var content_length: usize = 0;
            var body_out: []const u8 = undefined;
            defer self.allocator.free(body_out);

            if (self.body) |bd| {
                body_out = try std.json.stringifyAlloc(self.allocator, bd, std.json.StringifyOptions{});
                content_length = body_out.len;
            }
            const content_length_str = try std.fmt.allocPrint(self.allocator, "{}", .{content_length});
            try self.addHeader("Content-Length", content_length_str);

            var headerIter = self.headers.iter();
            while (headerIter.next()) |h| {
                try b.appendSlice(h.key);
                try b.appendSlice(": ");
                try b.appendSlice(h.value);
                try b.appendSlice("\r\n");
            }

            if (self.body) |_| {
                try b.appendSlice("\r\n");
                try b.appendSlice(body_out);
                try b.appendSlice("\r\n");
            }
        }
    };
}

pub const Response = struct {
    http_version: []const u8,
    status_code: u16,
    reason_phrase: []const u8,
    headers: OrderedStringMap([]const u8),
    body: []const u8,

    pub fn decode(allocator: std.mem.Allocator, bytes: []const u8) !@This() {
        var iter = std.mem.splitSequence(u8, bytes, "\r\n");
        const status_line = iter.next() orelse return error.MissingStatusLine;
        var status_line_iter = std.mem.tokenizeSequence(u8, status_line, " ");
        const http_version = status_line_iter.next() orelse return error.MissingHTTPVersion;
        const status_code_str = status_line_iter.next() orelse return error.MissingStatusCode;
        const status_code = try std.fmt.parseInt(u16, status_code_str, 10);
        const reason_phrase = status_line_iter.rest();

        var this = @This(){
            .http_version = http_version,
            .status_code = status_code,
            .reason_phrase = reason_phrase,
            .headers = OrderedStringMap([]const u8).init(allocator),
            .body = undefined,
        };

        while (iter.next()) |line| {
            if (line.len == 0) break;
            var parts = std.mem.tokenizeSequence(u8, line, ": ");
            const key = parts.next() orelse continue;
            const value = parts.next() orelse continue;
            this.headers.put(key, value) catch continue;
        }

        // empty line before body
        _ = iter.next() orelse return this;

        this.body = iter.rest();
        return this;
    }

    pub fn deinit(self: *@This()) void {
        self.headers.deinit();
    }
};

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

test "Response.decode without body" {
    const a = std.testing.allocator;

    const response_lines = [_][]const u8{
        "HTTP/1.1 200 OK",
        "Content-Type: text/html; charset=UTF-8",
        "Content-Length: 1234",
        "Set-Cookie: UserID=JohnDoe; Max-Age=3600; Version=1\r\n",
    };
    const input = try std.mem.join(a, "\r\n", &response_lines);
    defer a.free(input);

    var resp = try Response.decode(a, input);
    defer resp.deinit();

    try std.testing.expectEqualStrings("HTTP/1.1", resp.http_version);
    try std.testing.expectEqual(200, resp.status_code);
    try std.testing.expectEqualStrings("OK", resp.reason_phrase);
    try std.testing.expectEqualStrings(resp.headers.get("Content-Type").?, "text/html; charset=UTF-8");
}
