// An attribute to hide warnings for unused code.
#![allow(dead_code)]

#[derive(Debug)]
struct Person {
    name: String,
    age: u8,
}

// A unit struct
struct Unit;

// A tuple struct
struct Pair(i32, f32);

// A struct with two fields
#[derive(Debug)]
struct Point {
    x: f32,
    y: f32,
}

// Structs can be reused as fields of another struct
#[derive(Debug)]
struct Rectangle {
    // A rectangle can be specified by where the top left and bottom right
    // corners are in space.
    top_left: Point,
    bottom_right: Point,
    area: f32,
}

impl Rectangle {
    fn area(&mut self) -> f32 {
        let Rectangle { top_left: Point { x: x1, y: y1}, bottom_right: Point { x: x2, y: y2 }, area: _ } = *self;
        self.area = (x2 - x1).abs() * (y2 - y1).abs();
        self.area
    }
}

fn main() {
    // Create struct with field init shorthand
    let name = String::from("Peter");
    let age = 27;
    let peter = Person { name, age };

    // Print debug struct
    println!("{:?}", peter);

    // Instantiate a `Point`
    let point: Point = Point { x: 1.0, y: 4.0 };
    let another_point: Point = Point { x: 3.0, y: 1.0 };

    // Access the fields of the point
    println!("point coordinates: ({}, {})", point.x, point.y);

    // Destructure the point using a `let` binding
    let Point { x: left_edge, y: top_edge } = point;
    println!("le: {}, te: {}", left_edge, top_edge);

    let mut rectangle = Rectangle {
        // struct instantiation is an expression too
        top_left: Point { x: left_edge, y: top_edge },
        bottom_right: another_point,
        area: 0f32,
    };

    // Instantiate a unit struct
    let _unit = Unit;

    // Instantiate a tuple struct
    let pair = Pair(1, 0.1);

    // Access the fields of a tuple struct
    println!("pair contains {:?} and {:?}", pair.0, pair.1);

    // Destructure a tuple struct
    let Pair(integer, decimal) = pair;

    println!("pair contains {:?} and {:?}", integer, decimal);

    println!("area of rectangle: {}", rectangle.area());
}