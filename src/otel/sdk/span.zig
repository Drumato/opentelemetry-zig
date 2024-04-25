const std = @import("std");
const span = @import("../span.zig");
const Tracer = @import("tracer.zig").Tracer;

pub fn RecordingSpan(comptime SP: type) type {
    return struct {
        name: []const u8,
        tracer: *Tracer(SP),
        ctx: span.SpanContext,
        start_time_unixnano: []const u8,
        end_time_unixnano: []const u8,
        allocator: std.mem.Allocator,

        pub fn init(
            allocator: std.mem.Allocator,
            name: []const u8,
            tracer: *Tracer(SP),
            ctx: span.SpanContext,
        ) !@This() {
            const start_time_unixnano = try std.fmt.allocPrint(allocator, "{}", .{std.time.nanoTimestamp()});
            return @This(){
                .allocator = allocator,
                .name = name,
                .tracer = tracer,
                .ctx = ctx,
                .start_time_unixnano = start_time_unixnano,
                .end_time_unixnano = "",
            };
        }

        pub fn context(self: @This()) span.SpanContext {
            return self.ctx;
        }

        pub fn end(self: *@This()) !void {
            const end_time_unixnano = try std.fmt.allocPrint(self.allocator, "{}", .{std.time.nanoTimestamp()});
            self.end_time_unixnano = end_time_unixnano;
            try self.tracer.provider.processor.onEnd(self.tracer.provider.res, self);
        }

        pub fn traceIDString(self: @This()) ![]const u8 {
            const trace_id = try std.fmt.allocPrint(self.allocator, "{x:0>32}", .{self.ctx.trace_id});
            return trace_id;
        }

        pub fn spanIDString(self: @This()) ![]const u8 {
            const span_id = try std.fmt.allocPrint(self.allocator, "{x:0>16}", .{self.ctx.span_id});
            return span_id;
        }

        pub fn parentIDString(self: @This()) ![]const u8 {
            if (self.ctx.parent_id == 0) {
                return "";
            }

            const parent_id = try std.fmt.allocPrint(self.allocator, "{x:0>16}", .{self.ctx.parent_id});
            return parent_id;
        }

        pub fn startTimeUnixnano(self: @This()) []const u8 {
            return self.start_time_unixnano;
        }

        pub fn endTimeUnixnano(self: @This()) []const u8 {
            return self.end_time_unixnano;
        }
    };
}
