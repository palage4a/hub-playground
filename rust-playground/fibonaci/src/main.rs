fn main() {
    let x = 10;
    let res = fib1(x);
    println!("fib({x}) = {res}");
}

fn fib(x: i32) -> i32 {
    let mut f1 = 1;
    let mut f2 = 1;

    let mut n = 0;
    while n < x - 2 {
        let sum = f1 + f2;
        f1 = f2;
        f2 = sum;
        n = n + 1;
        println!("{n}: {f1} {f2}");
    }

    f2
}

fn fib1(x: i32) -> i32 {
    let mut f1 = 1;
    let mut f2 = 1;

    let mut n = 0;
    loop {
        let sum = f1 + f2;
        f1 = f2;
        f2 = sum;
        n = n + 1;
        if n == x - 2 {
            break f2;
        }
    }
}
