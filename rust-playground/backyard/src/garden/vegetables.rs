#[derive(Debug)]
pub struct Example(pub i32);

impl Example {
    pub fn parent_debug(&self) {
        let x = self;
        super::debug();
    }
}
