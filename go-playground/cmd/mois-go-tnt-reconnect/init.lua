box.cfg{}
box.schema.user.grant('guest', 'execute', 'universe', nil, { if_not_exists = true })
box.cfg{ listen = 3301 }
