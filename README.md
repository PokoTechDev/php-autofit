# php-autofit

Automatic PHP version switching based on `composer.json`. When you `cd` into a project, php-autofit reads the PHP version constraint from `composer.json` and switches to the matching Homebrew-installed PHP version automatically.

## Features

- **Automatic switching** — Detects `composer.json` via zsh `precmd` hook when you:
  - `cd` into a project directory
  - Open a terminal in your IDE
  - Switch git branches
- **Smart triggers** — Inside a git repository, only fires on git root or branch changes (not subdirectory navigation). Detached HEAD is detected by commit SHA.
- **Auto-install** — If the required PHP version is not installed, automatically runs `brew install`
- **Manual switching** — `phpuse 8.1` to switch manually
- **Composer-aware** — `phpuse-composer` reads `require.php` from `composer.json`

## Requirements

- macOS
- [Homebrew](https://brew.sh)
- zsh
- `jq` (optional — falls back to `grep` if not installed)

## Installation

```sh
curl -fsSL https://raw.githubusercontent.com/NaokiOouchi/php-autofit/main/install.sh | sh
```

Then reload your shell:

```sh
source ~/.zshrc
```

## Usage

### Automatic (default behavior)

Just `cd` into any project with a `composer.json` that specifies a PHP version:

```json
{
  "require": {
    "php": "^8.1"
  }
}
```

php-autofit will automatically switch to PHP 8.1.

### Manual

```sh
# Switch to a specific version
phpuse 8.1

# Switch based on composer.json in current directory
phpuse-composer
```

## How it works

1. A zsh `precmd` hook runs before each prompt
2. It checks if the git root or branch has changed (or the directory, outside git repos)
3. If changed, it looks for `composer.json` at the git root (or current directory)
4. Reads the PHP version from `require.php`
5. If the current PHP version differs, it unlinks the current version and links the target version via Homebrew

## Uninstall

Remove the source line from `~/.zshrc`:

```sh
sed -i '' '/php-autofit/d' ~/.zshrc
```

Remove the installed files:

```sh
rm -rf ~/.php-autofit
```

## License

MIT
