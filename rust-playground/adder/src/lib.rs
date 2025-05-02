#[derive(PartialEq,Debug)]
pub struct Rectangle {
    pub w: u32,
    pub h: u32,
}



impl Rectangle {
    /// can_hold returns true if the fist rectangle can hold the other one.
    /// otherwise, it returns false:
    ///
    /// ```
    /// let big = adder::Rectangle{w: 100, h: 100};
    /// let small = adder::Rectangle{w: 2,h: 2};
    ///
    /// assert!(big.can_hold(&small));
    /// assert!(!small.can_hold(&big));
    /// ```
    pub fn can_hold(&self, other: &Rectangle) -> bool {
        self.w > other.w && self.h > other.h
    }

    pub fn safe_divide(&self, divider: u32) -> Result<Rectangle,String> {
        match divider {
            0 => Err(format!("div by zero")),
            _ => Ok(Rectangle{w: self.w / divider, h: self.h / divider})
        }
    }
}

fn first_word_idx(s: &String) -> usize {
    s.chars().take_while(|x| *x != char::from(b' ')).count()
}

pub fn first_word(s: &String) -> &str {
    &s[0..first_word_idx(s)]
}

pub fn largest(l: &[i32]) -> &i32 {
    let mut largest = &l[0];

    for n in l {
        if n > largest {
            largest = n;
        }
    }

    largest
}

pub fn largest_char(l: &[char]) -> &char {
    let mut largest = &l[0];

    for n in l {
        if n > largest {
            largest = n;
        }
    }

    largest
}

pub fn largest_gen<T:std::cmp::PartialOrd>(l: &[T]) -> &T {
    let mut largest = &l[0];

    for n in l {
        if n > largest {
            largest = n;
        }
    }

    largest
}

pub struct Point<T,U> {
    x: T,
    y: U,
}

#[cfg(test)]
mod tests {
    use std::collections::HashMap;
    use super::*;

    #[test]
    fn equal_rects() {
        let r1 = Rectangle{w: 1, h: 1};
        let r2 = Rectangle{w: 1, h: 1};
        assert_eq!(r1, r2);

        let r3 = Rectangle{w: 2, h: 2};
        assert_ne!(r1, r3)
    }

    #[test]
    fn equal_rects_res() -> Result<(),String> {
        let r1 = Rectangle{w: 1, h: 1};
        let r2 = Rectangle{w: 1, h: 1};

        let re = match r1 == r2 {
            true => Ok(()),
            false => Err(format!("{:?} != {:?}", r1, r2)),
        };

        assert_eq!(Ok(()), re);

        let r3 = Rectangle{w: 2, h: 2};
        match r1 != r3 {
            true => Ok(()),
            false => Err(format!("{:?} != {:?}", r1, r3)),
        }

    }

    #[test]
    fn equal_rects_after_divied() -> Result<(),String> {
        let r1 = Rectangle{w: 2, h: 2};
        let r2 = Rectangle{w: 4, h: 4};
        let r3 = r2.safe_divide(2)?;

        match r1 == r3 {
            true => Ok(()),
            false => Err(format!("{:?} != {:?}", r1, r3)),
        }
    }

    #[test]
    fn check_first_word() {
        let s = String::from("Hello, world");
        let f = first_word(&s);

        assert_eq!(f, String::from("Hello,"));
    }

    #[test]
    fn check_first_word_with_single_word() {
        let s = String::from("Hello");
        let f = first_word(&s);

        assert_eq!(f, s);
    }

    #[test]
    fn check_first_word_with_empty_str() {
        let s = String::from("");
        let f = first_word(&s);

        assert_eq!(f, s);
    }

    #[test]
    fn option_map() {
        let a: Option<u32> = Some(5);
        assert_eq!(a.map(|x| x + 6), Some(11));

        let b: Option<i32> = None;
        assert_eq!(b.map(|x| x + 6), None);
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


    struct Msg<A> {
        v: A
    }

    impl Msg<String> {
        fn decode(&self) -> String {
            self.v.clone()
        }
    }

    impl Msg<i32> {
        fn decode(&self) -> i32 {
            self.v * self.v
        }
    }

    #[test]
    fn generics_usage() {
        let a = Some(3);
        let b = a.map(|x| x.to_string());

        assert_eq!(a, Some(3));
        assert_eq!(b, Some(String::from("3")));

        let c = Msg{v: String::from("1024")};
        let d = Msg{v: 32};

        assert_eq!(c.decode(), d.decode().to_string());
    }

    #[test]
    fn find_largest_manual() {
        let numbers = vec![32, 50, 2, 15];
        let mut largest = &numbers[0];

        for n in &numbers {
            if n > largest {
                largest = n;
            }
        }

        assert_eq!(50, *largest);
    }

    #[test]
    fn find_largest() {
        let numbers = vec![1, 2, 3, 100, 0, -2];
        let chars = vec!['a', 'b', 'e', '!'];
        {
            let largest_number = largest(&numbers);
            assert_eq!(100, *largest_number);
        }

        {
            let lchar = largest_char(&chars);
            assert_eq!('e', *lchar);
        }
        {
            let largest_num = largest_gen(&numbers);
            assert_eq!(100, *largest_num);

            let largest_char = largest_gen(&chars);
            assert_eq!('e', *largest_char);
        }

    }

    #[test]
    fn generic_multiple_type_usage() {
        let p1 = Point{x: 23, y: "str"};
        let p2 = Point{x: 23, y: 12};

        assert_eq!(p1.x, p2.x);
        assert_eq!("str", p1.y);
        assert_eq!(12, p2.y);
    }
}

