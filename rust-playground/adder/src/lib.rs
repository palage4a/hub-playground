#[derive(PartialEq,Debug)]
pub struct Rectangle {
    pub w: u32,
    pub h: u32,
}

impl Rectangle {
    pub fn can_hold(&self, other: Rectangle) -> bool {
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn can_hold_err() {
        let r1 = Rectangle{w: 1, h: 2};
        let r2 = Rectangle{w: 2,h: 2};
        assert!(!r1.can_hold(r2));
    }

    #[test]
    fn can_hold_success() {
        let r1 = Rectangle{w: 2,h: 2};
        let r2 = Rectangle{w: 1,h: 1};
        assert!(r1.can_hold(r2));
    }

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

        match r1 == r2 {
            true => Ok(()),
            false => Err(format!("{:?} != {:?}", r1, r2)),
        };

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
}

