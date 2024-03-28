pub const RecordingSpan = struct {
    name: []const u8,

    pub fn init(name: []const u8) @This() {
        return @This(){
            .name = name,
        };
    }

    pub fn end(self: @This()) void {
        _ = self;
    }
};
