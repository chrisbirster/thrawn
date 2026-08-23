const std = @import("std");
const th = @import("thrawn");

test "public validation rejects sibling alias collisions" {
    const remove: th.Command = .{ .name = "remove", .aliases = &.{"rm"} };
    const rm: th.Command = .{ .name = "rm" };
    const root: th.Command = .{ .name = "demo", .children = &.{ &remove, &rm } };
    try std.testing.expectError(error.DuplicateAlias, th.validation.validate(&root));
}

test "public validation rejects invalid positional ordering" {
    const root: th.Command = .{
        .name = "demo",
        .args = .{ .positionals = &.{
            .{ .name = "optional", .required = false },
            .{ .name = "required" },
        } },
    };
    try std.testing.expectError(error.RequiredPositionalAfterOptional, th.validation.validate(&root));
}
