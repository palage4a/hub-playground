// #[derive(Debug, Clone, Copy)]
// enum ShirtColor {
//     Red,
//     Blue,
// }

// struct Inventory {
//     shirts: Vec<ShirtColor>,
// }

// impl Inventory {
//     fn most_stocked(&self) -> ShirtColor {
//         let mut num_red = 0;
//         let mut num_blue = 0;

//         for c in &self.shirts {
//             match c {
//                 ShirtColor::Red => num_red += 1,
//                 ShirtColor::Blue => num_blue += 1,
//             };
//         }

//         if num_red > num_blue {
//             ShirtColor::Red
//         } else {
//             ShirtColor::Blue
//         }
//     }

//     fn giveaway(&self, usr_pref: Option<ShirtColor>) -> ShirtColor {
//         usr_pref.unwrap_or_else(|| self.most_stocked())
//     }
// }


// fn main() {
//     let store = Inventory{
//         shirts: vec![ShirtColor::Blue, ShirtColor::Red, ShirtColor::Blue],
//     };

//     let fpref = Some(ShirtColor::Red);
//     let fgift = store.giveaway(fpref);
//     println!("User with {fpref:?} gets {fgift:?}");

//     let spref = None;
//     let sgift = store.giveaway(spref);
//     println!("User with {spref:?} gets {sgift:?}");

// }

// use std::thread;

// fn main() {
//     let list = vec![1, 2, 3];
//     println!("Before defining closure: {list:?}");

//     thread::spawn(move || println!("From thread: {list:?}"))
//         .join()
//         .unwrap();

//     // println!("{list:?}");
// }


#[derive(Debug)]
struct Rectangle {
    width: u32,
    height: u32,
}

fn main() {
    let mut list = [
        Rectangle { width: 10, height: 1 },
        Rectangle { width: 3, height: 5 },
        Rectangle { width: 7, height: 12 },
    ];

    let mut sort_operations = vec![];
    let value = String::from("closure called");

    list.sort_by_key(|r| {
        sort_operations.push(value.clone());
        r.width
    });
    println!("{list:#?}");
}

#[cfg(test)]
mod tests {

    // #[test]
    // fn iter() {
    //     let v1 = vec![1,2];
    //     let expected = vec![1,2];
    //     let it = v1.iter();
    //     for i in it {
    //         assert_eq!(&expected[1], i);
    //     }
    // }

    #[test]
    fn mut_iter() {
        let v1 = vec![1,2];
        let mut it_mut = v1.iter();

        // borrowing value is allowed here.
        assert_eq!(v1[1], 2);

        assert_eq!(Some(&1), it_mut.next());
        assert_eq!(Some(&2), it_mut.next());
        assert_eq!(None, it_mut.next());
        assert_eq!(None, it_mut.next());
    }

    #[test]
    fn ino_iter() {
        let v1 = vec![1,2];
        let mut it_mut = v1.into_iter();

        // borrowing values is not allowed here due to it was moved.
        // assert_eq!(v1[1], 2);

        assert_eq!(Some(1), it_mut.next());
        assert_eq!(Some(2), it_mut.next());
        assert_eq!(None, it_mut.next());
        assert_eq!(None, it_mut.next());
    }

}
