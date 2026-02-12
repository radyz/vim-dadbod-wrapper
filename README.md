# vim-dadbod-wrapper

A Neovim plugin that provides some utilities to enhance `vim-dadbod` by managing database connections from environment variables or the macOS Keychain.

## Features

- **Flexible Connection Management**: Load database connection URLs from environment variables or securely from the macOS Keychain.
- **Smart Connection Switching**: Quickly execute queries against your favorite databases with a command that offers smart completion, prioritizing your most used and recently used connections.
- **Seamless `vim-dadbod` Integration**: Works on top of the powerful `vim-dadbod` plugin.

## Requirements

- [tpope/vim-dadbod](https://github.com/tpope/vim-dadbod)
- macOS (for Keychain support)

## Installation

You can install this plugin using your favorite plugin manager.

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
return {
    'tpope/vim-dadbod',
    {
        'radyz/vim-dadbod-wrapper',
        opts = {
            env_prefix = 'DADBOD_'
        }
    }
}
```

## Configuration

### Environment Variables

The plugin can load connections from environment variables that follow this format:

```
<PREFIX><CONNECTION_NAME>=<CONNECTION_URL>
```

```sh
export DADBOD_MY_POSTGRES="postgresql://user:pass@host:port/dbname"
export DADBOD_ANOTHER_DB="mysql://user:pass@host:port/dbname"
```

When Neovim starts, `vim-dadbod-wrapper` will automatically load these and make `my_postgres` and `another_db` available for the `:DBExec` command provided that the `env_prefix` option is supplied.

### macOS Keychain

For more secure storage, you can store your connection strings in the macOS Keychain. The plugin expects a "generic password" item where the "password" field contains connection details in a CSV format.

Each line in the secret should be in the format: `connection_name,connection_url`.

**Example:**

1.  Open **Keychain Access** app.
2.  Create a new "generic password" item (click the `+` button).
3.  Set "Keychain Item Name" to a label you'll remember, e.g., `neovim-dadbod`.
4.  The "Account Name" can be the same or something descriptive.
5.  In the "Password" field, enter your connection strings, one per line:

    ```
    my_keychain_db,postgresql://user:pass@host:port/dbname
    another_keychain_db,mysql://user:pass@host:port/dbname
    ```

6.  Save the item.

Now you can load these connections into Neovim using the `:DBLoadSecret` command.

### Optional Telescope support

Integration with telescope can be set with `require("telescope").load_extension("dadbod_wrapper")` somewhere in your config.

Example key bindings with `lazy.vim`:

```lua
return {
    'tpope/vim-dadbod',
    {
        'radyz/vim-dadbod-wrapper',
        opts = {
            env_prefix = 'DADBOD_'
        },
        keys = {
            {
                "<localleader>r",
                function()
                    require("telescope").extensions.dadbod_wrapper.connections(
                        require("telescope.themes").get_dropdown({
                            initial_mode = "normal",
                        })
                    )
                end,
                ft = { "sql" },
                mode = { "n", "v" },
            },
        },
    }
}
```

### Treesitter support

When using [Treesitter](https://github.com/nvim-treesitter/nvim-treesitter), any query modifying
database state will be prompted for confirmation before execution.

## Usage

### `:DBLoadSecret`

This command loads database connections from a specified macOS Keychain item.

```vim
:DBLoadSecret <keychain_label>
```

- `<keychain_label>`: The "Keychain Item Name" you used when creating the generic password item.

**Example:**

If you named your keychain item `neovim-dadbod`, you would run:

```vim
:DBLoadSecret neovim-dadbod
```

This will load `my_keychain_db` and `another_keychain_db` and make them available for use.

### `:DBExec`

This command executes a SQL query using a named connection. The query can be the entire buffer content or a visual selection.

```vim
:DBExec <connection_name>
```

- `<connection_name>`: The name of the connection to use (e.g., `my_postgres`, `my_keychain_db`).

The command provides smart completion for the connection name. Press `<Tab>` to see a list of available connections, sorted by your most frequently and recently used ones.

**Example:**

1.  Open a buffer and write a SQL query:

    ```sql
    SELECT * FROM users LIMIT 10;
    ```

2.  Execute the query against your `my_postgres` database:

    ```vim
    :DBExec my_postgres
    ```

3.  To execute only a part of the buffer, visually select the query and run the command:

    ```vim
    :'<,'>DBExec my_postgres
    ```

`vim-dadbod` will open a new split with the query results.

## License

MIT
