fn main() {
    println!("Hello, world!");
}

enum List {
    Cons(i32, Box<List>),
    Nil,
}

#[cfg(test)]
mod tests {
    use crate::List::{Cons, Nil};

    #[test]
    fn recursive_types() {
        let c1 = Cons(1, Box::new(Cons(2, Box::new(Cons(3, Box::new(Nil))))));
        let two_heads = match c1 {
            Cons(h, t) => (h, match *t { // dont sure it is correct to use *(deref syntax) here.
                Cons(nh, _) => nh,
                Nil => todo!(),
            }),
            Nil => todo!(),
        };

        assert_eq!(two_heads, (1, 2));
    }
}
