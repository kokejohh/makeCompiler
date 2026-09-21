pub const RETURN_ZERO =
    \\func i32 main() {
    \\  return 0;
    \\}
;

pub const RETURN_ZERO_WITH_INT =
    \\func i32 main() {
    \\  i32 number = 10;
    \\  return 0;
    \\}
;

pub const RETURN_10_PLUS_10 =
    \\func void main() {
    \\  return 10 + 10;
    \\}
;

pub const HELLO_WORLD =
    \\func void main() {
    \\  println("Hello world!");
    \\  return 0;
    \\}
;

pub const GLOBAL =
    \\i32 number = 10;
;
