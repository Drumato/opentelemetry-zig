const resource = @import("resource.zig");
const tracer = @import("tracer.zig");

pub const TracerProvider = struct {
    res: resource.Resource,

    pub fn init(res: resource.Resource) @This() {
        return @This(){
            .res = res,
        };
    }

    pub fn TracerType() type {
        return tracer.Tracer;
    }
};
