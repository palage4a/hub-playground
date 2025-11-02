use reqwest::{blocking,header};
use std::env;

pub fn gh_headers() -> header::HeaderMap {
    let mut h = header::HeaderMap::new();

    h.insert("Accept", "application/vnd.github+json".parse().unwrap());
    h.insert("X-GitHub-Api-Version", "2022-11-28".parse().unwrap());

    let token = env::vars()
        .filter(is_gh_token)
        .map(|(_, v)| v)
        .next()
        .unwrap();

    h.insert("Authorization", format!("Bearer {token}").parse().unwrap());
    h.insert("User-Agent", "palage4a-rust-script".parse().unwrap());

    h
}

pub fn gh_client(headers: header::HeaderMap) -> Result<blocking::Client,reqwest::Error> {
    blocking::Client::builder().
        default_headers(headers).
        build()
}

pub fn gh_jobs(c: blocking::Client, owner: String, repo: String) -> Result<blocking::Response,reqwest::Error> {
    c.get(format!("https://api.github.com/repos/{owner}/{repo}/actions/jobs"))
        .send()
}

pub fn gh_pulls(c: blocking::Client, owner: String, repo: String) -> Result<blocking::Response,reqwest::Error> {
    c.get(format!("https://api.github.com/repos/{owner}/{repo}/pulls"))
        .send()
}

pub fn gh_commits(c: blocking::Client, owner: String, repo: String) -> Result<blocking::Response,reqwest::Error> {
    c.get(format!("https://api.github.com/repos/{owner}/{repo}/commits"))
        .send()
}

fn is_gh_token(kv: &(String, String)) -> bool {
    kv.0 == "GH_TOKEN"
}

#[cfg(test)]
mod tests {
    use super::*;

    // #[test]
    // fn debug() -> Result<(),String>{
        // assert_eq!(env::vars().filter(is_gh_token).collect::<Vec<(String,String)>>(), vec![]);

        // assert_eq!(env::vars()
        //            .filter(is_gh_token)
        //            .map(|(k, _)| k)
        //            .next().unwrap(), "GH_TOKEN");

        // let headers = gh_headers();
        // assert_eq!(headers, header::HeaderMap::new());

        // let client = gh_client(headers).map_or_(|c| gh_jobs(c));
        // assert_eq!(client.unwrap(), blocking::Client::new())

        // assert_eq!(gh_jobs(client.unwrap(), String::from("palage4a"), String::from("dotfiles")).unwrap().status(), StatusCode::OK)

        // match gh_client(headers)
        //     .and_then(|c| gh_jobs(c, String::from("palage4a"), String::from("dotfiles")))
        //     .map(|r| r.status())
        //     .unwrap() {
        //         StatusCode::OK => Ok(()),
        //         s => Err(String::from(format!("found status {s:?}"))),
        //     }

    //     match gh_client(gh_headers())
    //         .and_then(|c| gh_commits(c, String::from("palage4a"), String::from("hub-playground")))
    //         .map(|r| r.te4xt())
    //         .unwrap() {
    //             StatusCode::OK => Ok(()),
    //             s => Err(String::from(format!("unexpected status {s:?}"))),
    //         }
    // }

	#[test]
	fn repl() {
		struct CustomSmartPointer {
			data: String,
		}

		impl Drop for CustomSmartPointer {
			fn drop(&mut self) {
				println!("call drop for cmp: {:?}", self.data);
			}
		}

		let c = CustomSmartPointer{
			data: String::from("debug")
		};

		// let d = CustomSmartPointer{
		// 	data: String::from("other stuff")
		// };

		// assert!(*d.data != *c.data)
	}
}
