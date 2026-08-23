const std = @import("std");

pub fn write(writer: *std.Io.Writer, executable: []const u8) !void {
    try writer.print(
        \\#compdef {s}
        \\# Zsh completion for {s}
        \\__thrawn_complete() {{
        \\    local -a candidates
        \\    candidates=("${{(@f)$({s} --thrawn-complete "${{words[@]:1}}")}}")
        \\    _describe 'values' candidates
        \\}}
        \\compdef __thrawn_complete {s}
        \\
    , .{ executable, executable, executable, executable });
}
