mod summary;
mod tweet;
mod news_article;

#[cfg(test)]
mod tests {
    use crate::summary::Summary;
    use crate::tweet::Tweet;
    use crate::news_article::NewsArticle;

    #[test]
    fn tweet_summarize() {
        let tweet = Tweet::new(1, String::from("russia"));
        assert_eq!("Tweet #1 about russia", tweet.summarize());
    }

    #[test]
    fn newsarticle_summarize() {
        let na = NewsArticle{id: 1, location: String::from("russia"), content: String::from("Putin")};
        assert_eq!("Article #1 from russia about Putin", na.summarize());
    }
}
