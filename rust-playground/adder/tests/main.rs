use adder::{Rectangle};

mod common;

#[test]
fn can_hold_err() {
    let r1 = Rectangle{w: 1, h: 2};
    let r2 = Rectangle{w: 2,h: 2};
    assert!(!r1.can_hold(r2));
}
