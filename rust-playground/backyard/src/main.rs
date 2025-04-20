use garden::vegetables::Example;

mod garden;

fn main() {
    let e = Example(3);
    println!("Example: {:?}, field: {}", e, e.0);
    println!("Hello, world!");
    e.parent_debug();
}
