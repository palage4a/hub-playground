use std::{env, process};
use minigrep::Config;

fn main() {
    let args: Vec<String> = env::args().collect();

    let config = Config::build(&args).unwrap_or_else(|err|{
        println!("Arguments parsing error: {err}");
        process::exit(1);
    });

    if let Err(e) = minigrep::run(config) {
        println!("Aplication error: {e}");
        process::exit(1);
    }
}
