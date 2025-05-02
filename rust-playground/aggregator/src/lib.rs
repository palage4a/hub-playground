mod summary;
mod tweet;
mod news_article;
mod blog_post;

use summary::Summary;

fn tweet_summarize_fn(t: tweet::Tweet) -> String {
    t.summarize()
}

fn summarize_caller(s: &impl Summary) -> String {
    s.summarize()
}

#[cfg(test)]
mod tests {
    use super::*;

    use crate::summary::Summary;
    use crate::tweet::Tweet;
    use crate::news_article::NewsArticle;
    use crate::blog_post::BlogPost;

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

    #[test]
    fn tweet_summarize_fn_global() {
        let t = Tweet::new(2, String::from("something"));
        assert_eq!("Tweet #2 about something", tweet_summarize_fn(t));
    }

    #[test]
    fn blog_post_summarize_default_impl() {
        let b = BlogPost::new(String::from("Ivan"), String::from("go-tarantool"));
        assert_eq!("Read more...", b.summarize());
    }

    #[test]
    fn trait_as_parameter() {
        let t = Tweet::new(1, String::from("cringe"));

        assert_eq!("Tweet #1 about cringe", summarize_caller(&t));
    }
}
