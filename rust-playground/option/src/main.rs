fn main() {
    let x: Option<u32> = Some(5);
    let (w, y, z) = (1,2,3);
    match x {
        Some(x) => println!("Hello, world! - {}", x),
        None => todo!(),
    };
    println!("{}, {}, {}", w, y, z);
}
