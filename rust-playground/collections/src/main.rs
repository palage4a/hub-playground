use std::collections::HashMap;

fn mode(v: &Vec<i32>) -> i32 {
    let mut hm = HashMap::new();
    let mut mode = 0;

    for i in v {
        let count = hm.entry(*i).or_insert(0);
        *count += 1;
        mode = if *count > mode { *count } else { mode };
    }

    mode
}

fn median(v :&Vec<i32>) -> i32 {
    v.get(v.len() / 2).copied().unwrap()
}

fn main() {
    let a = String::from("Abs");
    let b = "Qwer";

    let c = a + b;

    println!("Hello, world =  {}!", c);


    let mut hm = HashMap::new();

    hm.insert("k", 3);

    println!("{}", hm.get("k").copied().unwrap_or(0));
    hm.insert("a", 2);

    println!("{:?}", hm);

    let mut scores = HashMap::new();
    scores.insert(String::from("Blue"), 10);

    scores.entry(String::from("Yellow")).or_insert(50); // insert
    scores.entry(String::from("Blue")).or_insert(50); // no insert

    println!("{scores:?}");

    let vec = vec![1,2,2,2,2,2,3,3,3,4,5];
    let mode = mode(&vec);
    let med = median(&vec);
    println!("Median: {}, Mode: {}", med, mode);
}
