const std = @import("std");

const digits = [_]u8{ '1', '2', '3', '4', '5', '6', '7', '8', '9', '0' };
const Point = struct { x: i32, y: i32 };
const neighbor_points_offsets = [_]Point{ .{ .x = -1, .y = 1 }, .{ .x = 0, .y = 1 }, .{ .x = 1, .y = 1 }, .{ .x = -1, .y = 0 }, .{ .x = 1, .y = 0 }, .{ .x = -1, .y = -1 }, .{ .x = 0, .y = -1 }, .{ .x = 1, .y = -1 } };

const Number = struct {
    digits: []u8,
    representation: u16,
    grid_x: u64,
    grid_y: u64,

    pub fn init(schematics_digits: []u8, grid_x: u64, grid_y: u64) !Number {
        const repr = try std.fmt.parseInt(u16, schematics_digits, 10);
        return .{ .digits = schematics_digits, .representation = repr, .grid_x = grid_x, .grid_y = grid_y };
    }
};

const Schematics = struct {
    allocator: std.mem.Allocator,
    cells: []u8,
    width: u64,
    height: u64,

    pub fn init(allocator: std.mem.Allocator, input: []const u8) !Schematics {
        var it = std.mem.tokenizeAny(u8, input, "\n");
        const line_length = it.next().?.len;
        const file_lines = input.len / line_length;

        const cells: []u8 = try allocator.alloc(u8, line_length * file_lines);
        var x: u8 = 0;
        var y: u8 = 0;
        for (input) |char| {
            std.debug.print("{s}", .{[_]u8{char}});

            cells[(y * file_lines) + x] = char;
            if (x < line_length) {
                x += 1;
            } else {
                x = 0;
                y += 1;
            }
        }

        return .{ .allocator = allocator, .cells = cells, .width = line_length, .height = file_lines };
    }

    pub fn deinit(self: *Schematics) void {
        self.allocator.free(self.cells);
    }

    pub fn get(self: *Schematics, x: u64, y: u64) u8 {
        return self.cells[(y * self.width) + x];
    }

    pub fn set(self: *Schematics, x: u64, y: u64, val: u8) void {
        self.cells[(y * self.width) + x] = val;
    }

    pub fn print(self: *Schematics) void {
        for (0..self.height) |grid_y| {
            for (0..self.width) |grid_x| {
                std.debug.print("{s}", .{[_]u8{self.get(grid_x, grid_y)}});
            }
            std.debug.print("\n", .{});
        }
    }

    pub fn erase_around_symbols(self: *Schematics, allocator: std.mem.Allocator) !void {
        var symbol_points = std.ArrayList(Point).init(allocator);

        for (0..self.height) |grid_y| {
            for (0..self.width) |grid_x| {
                const symbol = self.get(grid_x, grid_y);
                const coord_x: i32 = @intCast(grid_x);
                const coord_y: i32 = @intCast(grid_y);
                if (!is_digit(symbol) and symbol != '.' and symbol != '\n') {
                    try symbol_points.append(.{ .x = coord_x, .y = coord_y });
                }
            }
        }

        for (symbol_points.items) |point| {
            const grid_x = point.x;
            const grid_y = point.y;

            for (neighbor_points_offsets) |neighbor| {
                var x: i64 = @intCast(grid_x);
                var y: i64 = @intCast(grid_y);
                var neigh_x: i64 = neighbor.x + x;
                var neigh_y: i64 = neighbor.y + y;

                if (neigh_x < 0 or neigh_x > self.width) {
                    continue;
                }
                if (neigh_y < 0 or neigh_y > self.height) {
                    continue;
                }

                var schematics_x: u64 = @intCast(neigh_x);
                var schematics_y: u64 = @intCast(neigh_y);
                var symbol = self.get(schematics_x, schematics_y);
                if (symbol == '\n') {
                    continue;
                }
                self.set(schematics_x, schematics_y, '*');
            }
        }
    }
};

fn is_digit(symbol: u8) bool {
    for (digits) |digit| {
        if (symbol == digit) {
            return true;
        }
    }

    return false;
}

fn find_numbers(allocator: std.mem.Allocator, schematics: Schematics) ![]Number {
    var numbers = std.ArrayList(Number).init(allocator);
    var current_digits = std.ArrayList(u8).init(allocator);

    var symbol: u8 = undefined;
    var current_number_x: u64 = 0;
    var current_number_y: u64 = 0;
    var in_number = false;

    for (0..schematics.height) |grid_y| {
        for (0..schematics.width) |grid_x| {
            var sc = schematics;
            symbol = sc.get(grid_x, grid_y);
            if (is_digit(symbol)) {
                try current_digits.append(symbol);

                if (!in_number) {
                    current_number_x = grid_x;
                    current_number_y = grid_y;
                    in_number = true;
                }
            } else {
                if (in_number) {
                    in_number = false;
                    try numbers.append(try Number.init(current_digits.items, current_number_x, current_number_y));
                    current_digits = std.ArrayList(u8).init(allocator);
                }
            }
        }
    }

    return numbers.items;
}

fn read_file_into_buf(allocator: std.mem.Allocator, filename: []const u8) ![]u8 {
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    const file_size = (try file.stat()).size;
    const read_buf = try file.readToEndAlloc(allocator, file_size);
    return read_buf;
}

pub fn main() !void {
    const file_buf = try read_file_into_buf(std.heap.page_allocator, "./input/day3");
    defer std.heap.page_allocator.free(file_buf);

    var schematics = try Schematics.init(std.heap.page_allocator, file_buf);

    const numbers_before = try find_numbers(std.heap.page_allocator, schematics);
    schematics.print();

    try schematics.erase_around_symbols(std.heap.page_allocator);
    schematics.print();
    const numbers_after = try find_numbers(std.heap.page_allocator, schematics);

    var total: u32 = 0;
    for (numbers_before) |num_1| {
        for (numbers_after) |num_2| {
            if (num_2.grid_x == num_1.grid_x and num_2.grid_y == num_1.grid_y and num_2.representation == num_1.representation) {
                total += num_1.representation;
            }
        }
    }

    var sum: u32 = 0;
    for (numbers_before) |num| {
        sum += num.representation;
    }
    std.debug.print("day 3 part 1: {d}\n", .{sum - total});

    defer schematics.deinit();
}
