#[derive(Debug)]
struct Rect {
    width: u32,
    height: u32,
}

impl Rect {
    fn area(&self) -> u32 {
        self.width * self.height
    }

    fn square(size: u32) -> Self {
        Self{
            width: size,
            height: size,
        }
    }

    fn width(&self) -> bool {
        self.width > 0
    }

}

fn main() {
    let rect1 = Rect{
        width: 50,
        height: 30
    };

    println!("{:?}", rect1);

    let a = rect1.area();

    println!(
        "The area of the rectangle ({0}, {1}) is {a} square pixels.",
        rect1.width, rect1.height,
    );

    if rect1.width() == true {
        println!("rect1 has a width: {}", rect1.width);
    }

    println!("Rectangle is {0:?}", rect1);

    let s = Rect::square(10);
    println!("Square is {:?}", s);
}
