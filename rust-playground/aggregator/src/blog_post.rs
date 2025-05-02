use crate::summary::Summary;

pub struct BlogPost {
    author: String,
    content: String,
}

impl BlogPost {
    pub fn new(author: String, content: String) -> Self {
        Self {author, content}
    }
}

impl Summary for BlogPost{}
