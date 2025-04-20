use serde::{Serialize, Deserialize};
use tarantool::{
    proc,
    space::Space,
    tuple::{Tuple, AsTuple},
};

// Структура для пользователя
#[derive(Debug, Serialize, Deserialize)]
struct User {
    id: u32,
    name: String,
}

// Реализация конвертации в кортеж Tarantool
impl Tuple for User {}

// Экспортируемая функция для вставки пользователя
#[proc]
fn insert_user() -> Result<(), String> {
    let space = Space::find("users").ok_or("Space 'users' not found")?;
    let user = User { id: 1, name: "Alice".to_string() };
    let _ = space.replace(&user.as_tuple()?)?;
    Ok(())
}

// Экспортируемая функция для получения пользователя
#[proc]
fn get_user(user_id: u32) -> Result<Option<User>, String> {
    let space = Space::find("users").ok_or("Space 'users' not found")?;
    let key = (user_id,);
    match space.select(&key)? {
        Some(tuple) => {
            let user: User = tuple.decode()?;
            Ok(Some(user))
        }
        None => Ok(None),
    }
}