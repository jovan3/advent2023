const std = @import("std");

const Game = struct { part_1: u16, part_2: u16 };

fn str_to_int(s: []const u8) !u8 {
    const result = try std.fmt.parseInt(u8, s, 10);
    return result;
}

fn extract_game_id(line: []const u8) !u8 {
    const game_part = std.mem.indexOfScalar(u8, line, ':').?;
    const game = std.mem.indexOfScalar(u8, line[0..game_part], ' ').?;

    return try str_to_int(line[(game + 1)..game_part]);
}

fn game_possible(line: []const u8) !bool {
    const cubes_part = std.mem.indexOfScalar(u8, line, ':').?;
    const cubes_string = std.mem.trim(u8, line[cubes_part..], ": ");

    var cube_games = std.mem.split(u8, cubes_string, "; ");
    while (cube_games.next()) |cube_game| {
        var blue: u8 = 0;
        var red: u8 = 0;
        var green: u8 = 0;

        var cube_colors = std.mem.split(u8, cube_game, ", ");
        while (cube_colors.next()) |cube_color| {
            const cube_color_delimiter = std.mem.indexOfScalar(u8, cube_color, ' ').?;
            const cube_color_count = try str_to_int(cube_color[0..cube_color_delimiter]);
            const cube_color_name = std.mem.trim(u8, cube_color[cube_color_delimiter..], " ");

            if (std.mem.eql(u8, cube_color_name, "blue")) {
                blue += cube_color_count;
            } else if (std.mem.eql(u8, cube_color_name, "red")) {
                red += cube_color_count;
            } else if (std.mem.eql(u8, cube_color_name, "green")) {
                green += cube_color_count;
            }
        }

        if (red > 12 or green > 13 or blue > 14) {
            return false;
        }
    }

    return true;
}

fn game_fewest_possible(line: []const u8) !u16 {
    const cubes_part = std.mem.indexOfScalar(u8, line, ':').?;
    const cubes_string = std.mem.trim(u8, line[cubes_part..], ": ");

    var blue_max: u16 = 0;
    var red_max: u16 = 0;
    var green_max: u16 = 0;

    var cube_games = std.mem.split(u8, cubes_string, "; ");
    while (cube_games.next()) |cube_game| {
        var cube_colors = std.mem.split(u8, cube_game, ", ");
        while (cube_colors.next()) |cube_color| {
            const cube_color_delimiter = std.mem.indexOfScalar(u8, cube_color, ' ').?;
            const cube_color_count = try str_to_int(cube_color[0..cube_color_delimiter]);
            const cube_color_name = std.mem.trim(u8, cube_color[cube_color_delimiter..], " ");

            if (std.mem.eql(u8, cube_color_name, "blue") and blue_max < cube_color_count) {
                blue_max = cube_color_count;
            } else if (std.mem.eql(u8, cube_color_name, "red") and red_max < cube_color_count) {
                red_max = cube_color_count;
            } else if (std.mem.eql(u8, cube_color_name, "green") and green_max < cube_color_count) {
                green_max = cube_color_count;
            }
        }
    }

    return blue_max * red_max * green_max;
}

fn process_line(line: []const u8) !Game {
    const game_id = try extract_game_id(line);
    const valid_game = try game_possible(line);

    var part_1: u16 = 0;
    if (valid_game) {
        part_1 = game_id;
    }

    const part_2 = try game_fewest_possible(line);

    return .{ .part_1 = part_1, .part_2 = part_2 };
}

pub fn main() !void {
    const file = try std.fs.cwd().openFile("./input/day2", .{});
    defer file.close();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const read_buf = try file.readToEndAlloc(allocator, 1024 * 1024);
    defer allocator.free(read_buf);
    var it = std.mem.tokenizeAny(u8, read_buf, "\n");

    var part_1_sum: u16 = 0;
    var part_2_sum: u32 = 0;
    while (it.next()) |line| {
        const line_result = try process_line(line);
        part_1_sum += line_result.part_1;
        part_2_sum += line_result.part_2;
    }

    std.debug.print("Day 2 part 1: {d}\n", .{part_1_sum});
    std.debug.print("Day 2 part 2: {d}\n", .{part_2_sum});
}
