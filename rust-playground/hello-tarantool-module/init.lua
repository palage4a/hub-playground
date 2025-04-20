-- Создайте файл init.lua
box.cfg{
    listen = 3301,
    wal_mode = 'none'
}

-- Создайте пространство 'users'
box.schema.space.create('users', { if_not_exists = true })
box.space.users:format({
    { name = 'id', type = 'unsigned' },
    { name = 'name', type = 'string' },
})
box.space.users:create_index('primary', { parts = { 'id' } })

-- Загрузите Rust-модуль
local rust_module = require('tarantool_example')

-- Вызов функций из Rust
function insert_example()
    return rust_module.insert_user()
end

function get_example(user_id)
    return rust_module.get_user(user_id)
end