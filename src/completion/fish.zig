const std = @import("std");

pub fn write(writer: *std.Io.Writer, executable: []const u8) !void {
    try writer.print(
        \\# Fish completion for {s}
        \\function __thrawn_complete
        \\    set -l tokens (commandline -opc)
        \\    set -l current (commandline -ct)
        \\    {s} --thrawn-complete $tokens[2..-1] $current
        \\end
        \\complete -c {s} -f -a '(__thrawn_complete)'
        \\
    , .{ executable, executable, executable });
}
