use std::io;
use std::cmp::Ordering;
use rand::Rng;

fn main() {
    println!("Guessing number game");

    let secret_number = rand::thread_rng().gen_range(1..=100);
    println!("Secret number: {}", secret_number);

    loop {
        println!("Input your guessed number:");

        let mut guess = String::new();
        io::stdin()
            .read_line(&mut guess)
            .expect("Failed to read from stdin");


        let guess: u32 = match guess.trim().parse() {
            Ok(num) => num,
            Err(_) => continue,
        };

        println!("You guessed number: {}", guess);

        match guess.cmp(&secret_number) {
            Ordering::Less => println!("Less"),
            Ordering::Greater => println!("Greater"),
            Ordering::Equal => {
                println!("You win");
                break;
            }
        }
    }

}
