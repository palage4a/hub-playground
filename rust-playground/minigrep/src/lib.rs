use std::{env,fs};
use std::error::Error;

pub fn run(config: Config) -> Result<(), Box<dyn Error>>{
    let content = fs::read_to_string(config.filepath)?;

    // Imperative
    //
    // let results = if config.ignore_case {
    //     search_case_insensetive(&config.query, &content)
    // } else {
    //     search(&config.query, &content)
    // }

    // for line in results{
    //     println!("{line}");
    // }

    // Declarative
    //
    if config.ignore_case {
        search_case_insensetive(&config.query, &content)
    } else {
        search(&config.query, &content)
    }.iter().for_each(|line| println!("{line}"));

    Ok(())
}

pub struct Config {
    pub query: String,
    pub filepath: String,
    pub ignore_case: bool,
}

impl Config {
    pub fn build(mut args: impl Iterator<Item=String>) -> Result<Self, &'static str> {
        args.next();

        let query = match args.next() {
            Some(arg) => arg,
            None => return Err("query arg is empty"),
        };

        let filepath = match args.next() {
            Some(arg) => arg,
            None => return Err("filepath arg is empty"),
        };

        let ignore_case = match args.next() {
            Some(arg) => arg == "-i" && match args.next() {
                Some(narg) => narg == "true",
                None => false,
            },
            None => env::var("IGNORE_CASE").is_ok()
        };

        Ok(Self {
            query,
            filepath,
            ignore_case,
        })
    }
}

fn search<'a>(q: &str, c: &'a str) -> Vec<&'a str> {
    // Imperative implementation
    //
    // let mut results = Vec::new();
    // for line in c.lines() {
    //     if line.contains(q) {
    //         results.push(line);
    //     }
    // }

    // Declarative implementation
    //
    c.lines()
        .filter(|l| { l.contains(q) })
        .collect()
}

fn search_case_insensetive<'a>(q: &str, c: &'a str) -> Vec<&'a str> {
    // Imperative implementation
    //
    // let query = q.to_lowercase();
    // let mut results = Vec::new();
    // for line in c.lines() {
    //     if line.to_lowercase().contains(&query) {
    //         results.push(line)
    //     }
    // }

    // results

    // Declarative implementation
    //
    c.lines()
        .filter(|line| line.to_lowercase().contains(&q.to_lowercase()))
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn case_sensitive() {
        let query = "saf";
        let content = "\
rust
safe, fast, memory like
end of content
";
        assert_eq!(vec!["safe, fast, memory like"], search(query, content));
    }

    #[test]
    fn case_insensitive() {
        let query = "mEm";
        let content = "\
rust
Safe, fast, memory like
Memopedia
end of content
";
        assert_eq!(vec!["Safe, fast, memory like", "Memopedia"], search_case_insensetive(query, content));
    }

}
