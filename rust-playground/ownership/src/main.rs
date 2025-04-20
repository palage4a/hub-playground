fn main() {
    let s = String::from("hello");
    takes_ownership(s);
    println!("{s}");

    let x = 5;
    makes_copy(x);
    println!("{x}");
}

fn takes_ownership(some_string: String) { // some_string comes into scope
    println!("{some_string}");
} // Here, some_string goes out of scope and `drop` is called. The backing
  // memory is freed.

fn makes_copy(some_integer: i32) {
    println!("{some_integer}");
} // Here, some_integer goes out of scope. Nothing special happens cuz it.
