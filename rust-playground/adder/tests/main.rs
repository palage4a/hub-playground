use adder::{Rectangle};
use std::collections::HashMap;

mod common;

#[test]
fn can_hold_err() {
    let r1 = Rectangle{w: 1, h: 2};
    let r2 = Rectangle{w: 2,h: 2};
    assert!(!r1.can_hold(r2));
}


#[test]
fn vector_usage() {
    let v = vec![2,5,3];

    assert_eq!(v.get(2), Some(&3));
    assert_eq!(v.get(3), None);

    assert_eq!(v[2], 3);
    // println!("{}", v[3]);


    for i in &v {
        println!("{}", i);
    }
}

#[test]
fn hasmap_usage() {
    let mut m = HashMap::new();

    let key = "key1";
    let value = "value1";

    let skey = String::from(key);
    let svalue = String::from(value);

    m.insert(skey, svalue.clone());
    assert_eq!(m.get(&String::from(key)), Some(&String::from(value)));
}
