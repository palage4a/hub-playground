use crate::summary::Summary;

pub struct Tweet {
    id: i32,
    content: String,
}

impl Tweet {
    pub fn new(id: i32, content: String) -> Tweet {
        Tweet{id, content}
    }
}

impl Summary for Tweet {
    fn summarize(self) -> String {
        String::from(format!("Tweet #{} about {}", self.id, self.content))
    }
}
