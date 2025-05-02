use crate::summary::Summary;

pub struct NewsArticle {
    pub id: i32,
    pub location: String,
    pub content: String,
}

impl Summary for NewsArticle {
    fn summarize(self) -> String {
        String::from(format!("Article #{} from {} about {}", self.id, self.location, self.content))
    }
}
