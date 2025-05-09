use std::fs;
use std::error::Error;

pub fn run(config: Config) -> Result<(), Box<dyn Error>>{
    let content = fs::read_to_string(config.filepath)?;

    Ok(())
}

pub struct Config {
    pub query: String,
    pub filepath: String,
}

impl Config {
    pub fn build(args: &[String]) -> Result<Self, &'static str> {
        if args.len() < 3 {
            return Err("not enough arguments")
        }

        Ok(Self {
            query: args[1].clone(),
            filepath: args[2].clone(),
        })
    }
}

fn search<'a>(q: &str, c: &'a str) -> Vec<&'a str> {
    vec![]
}


#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn one_result() {
        let query = "saf";
        let content = "\
rust
safe, fast, memory like
end of content
";
        assert_eq!(vec!["safe, fast, memory like"], search(query, content));
    }
}
