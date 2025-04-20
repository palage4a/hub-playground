use std::{thread, time};

fn inc(x: u64) -> u64 {
    let x = x + 1;
    let ten_ms = time::Duration::from_millis(1);
    thread::sleep(ten_ms);
    println!("{x}");
    inc(x)
}

fn main() {
    inc(0);
    println!("Hello, world!");
}
