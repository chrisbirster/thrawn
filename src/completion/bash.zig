const std = @import("std");

pub fn write(writer: *std.Io.Writer, executable: []const u8) !void {
    try writer.print(
        \\# Bash completion for {s}
        \\__thrawn_complete() {{
        \\    local -a candidates
        \\    mapfile -t candidates < <({s} --thrawn-complete "${{COMP_WORDS[@]:1:$COMP_CWORD}}")
        \\    COMPREPLY=("${{candidates[@]}}")
        \\}}
        \\complete -F __thrawn_complete {s}
        \\
    , .{ executable, executable, executable });
}
