# Okeanos’ dotfiles

![Screenshot of my shell prompt](screenshot.png)

## Installation

**Warning:** If you want to give these `dotfiles` a try, you should first fork this repository, review the code, and
remove things you don’t want or need. Don’t blindly use my settings unless you know what that entails. Use at your own
risk!

**Warning:** For this to work properly on macOS Mojave and later read [this issue](https://github.com/mathiasbynens/dotfiles/issues/849)
carefully and add all necessary binaries (e.g. `iTerm`, `Terminal`, and possibly `bash` as listed in `/etc/shells`) to the
`System Settings > Privacy & Security > Full Disk Access` list.

**Warning:** On macOS Ventura and later there exists an additional security setting called `App Management`. `iTerm`,
and `Terminal` may have to be added to the list in `System Settings > Privacy & Security > App Management` to be able to
install and Homebrew casks.

### Getting Started

1. Manually download the [`do`](https://raw.githubusercontent.com/Okeanos/dotfiles/main/do) script

  ```bash
  curl -sSL -o ~/Downloads/do https://raw.githubusercontent.com/Okeanos/dotfiles/main/do
  chmod +x ~/Downloads/do
  ```

1. Execute `do link` from your shell after reviewing it
2. **Optionally** and **after a careful review** you can now run `macos.sh` from the `dotfiles` repository
  Please note that this requires `bash` to have `Full Disk Access` as described above!

#### Enabling (Brew) Installed Tools

These dotfiles contain a few additional tools that have to be properly registered to work:

- [QLMarkdown](https://github.com/sbarex/QLMarkdown) (QuickLook Extension)
- [Syntax Highlighter](https://github.com/sbarex/SourceCodeSyntaxHighlight) (QuickLook Extension)

Follow the instructions as presented in the repositories for this to work as expected. Additionally, you should
probably manually open each application from within the `/Applications` folder manually once to ensure they work
as expected. Mainly because macOS will, in some cases (depending on how the apps were signed for example) ask for
additional confirmation once and prevent e.g. auto-start of these apps until then.

#### iTerm/Terminal Theming

These dotfiles use [Selenized](https://github.com/jan-warchol/selenized) as an alternative to the ever-popular [Solarized](https://github.com/altercation/solarized).

iTerm, Terminal, etc. do not ship with that theme out of the box. If you use the `macos.sh` script, both themes will be
imported as color profiles into iTerm (but not Terminal for reasons explained [here](https://github.com/jan-warchol/selenized/tree/master/terminals/terminal-app)
and [here](https://github.com/altercation/solarized/tree/master/osx-terminal.app-colors-solarized)). You can then choose
whichever you want for your profile. To do so select it in
`Settings > Profiles > [Profile Name] > Colors > Color Presets…` within iTerm (or manually import it from there if you
did not run `macos.sh`).

If you want a dark theme or different color set (e.g. `white` instead of `light`) don't forget to pass the appropriate
flag when running `do link`.

Alternatively, set the following for individual tools beyond iTerm:

- [bat](https://github.com/sharkdp/bat): `--theme="Selenized-Light"` to `--theme="Selenized-Dark"` in
  `stow/shell/dot-config/bat/config`
  - also applicable for [`delta`](https://github.com/dandavison/delta) (used for git diffs)
- Vim: `background=light` to `background=dark` in `stow/shell/dot-config/vim/vimrc`
- Visual Studio Code: `"workbench.colorTheme": "Default Light+"` to `"workbench.colorTheme": "Default Dark+"` in
  `stow/vscode/setting.json`

#### Lightweight Editor

The aforementioned `Brewfile` includes [Visual Studio Code](https://code.visualstudio.com) ("VSCode"), i.e. the
non-free, proprietary Microsoft product that includes telemetry etc., as a lightweight GUI editor. Either disable
telemetry manually if you are bothered by it (e.g. as described in
[this gist](https://gist.github.com/hyperupcall/99e355405611be6c4e0a38b6e3e8aad0)) or switch to another editor, e.g.:

- [BBedit](https://www.barebones.com/products/bbedit/)
- [Nova](https://nova.app)
- [Sublime Text](https://www.sublimetext.com)
- [VSCodium](https://vscodium.com)
- [Zed](https://zed.dev)
- …

#### Sensible macOS defaults (`macos.sh`)

When setting up a new Mac, you may want to set some sensible macOS defaults. Please note that you really ought to read
the contents of the following script very, very carefully because it changes a large number of system settings. You can
apply it by invoking it like this:

```bash
cd ~/Developer/dotfiles && ./macos.sh
```

## Modifying the `$PATH`

If `~/.path` exists, it will be sourced along with the other files, before any feature testing (such as
[detecting which version of `ls` is being used](https://github.com/mathiasbynens/dotfiles/blob/aff769fd75225d8f2e481185a71d5e05b76002dc/.aliases#L21-L26))
takes place.

Here’s an example `~/.path` file that adds `/usr/local/bin` to the `$PATH`:

```bash
export PATH="/usr/local/bin:$PATH"
```

## Add custom commands without creating a new fork

If `~/.extra` exists, it will be sourced along with the other files. You can use this to add a few custom commands
without the need to fork this entire repository, or to add commands you don’t want to commit to a public repository.

An example of `~/.extra` by the original author of this repository looks something like this:

```bash
# Git credentials
# Not in the repository, to prevent people from accidentally committing under my name
GIT_AUTHOR_NAME="Foo Bar"
GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
git config --global user.name "$GIT_AUTHOR_NAME"
GIT_AUTHOR_EMAIL="foo.bar@example.org"
GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"
git config --global user.email "$GIT_AUTHOR_EMAIL"
```

You could also use `~/.extra` to override settings, functions and aliases from my dotfiles repository. It’s probably
better to [fork this repository](https://github.com/Okeanos/dotfiles/fork) instead, though.

## Unlinking / Uninstalling

If you want to unlink particular dotfiles (e.g. for `vim`) you can execute the following command:

```bash
~/Developer/dotfiles/do -d 'vim' unlink
```

Or do it via the raw stow invocation:

```bash
cd ~/Developer/dotfiles && stow --dotfiles --delete --dir "stow" "vim" -t "${HOME}"
```

If you want to unlink (uninstall) all dotfiles managed by this repository you can use the `do unlink` script. This
operation is non-destructive and will only remove the symlinks from your `${HOME}` directory. Any customizations,
e.g. `.extra` or `.gituser`, that were created by you will stay in `${HOME}`. You can restore the dotfiles again by
running `do link`.

```bash
~/Developer/dotfiles/do unlink
```

## Original Author

These dotfiles are a largely rewritten/updated [fork](https://github.com/mathiasbynens/dotfiles) based on the work of:

| [![twitter/mathias](https://gravatar.com/avatar/24e08a9ea84deb17ae121074d0f17125?s=70)](https://twitter.com/mathias "Follow @mathias on Twitter") |
|---------------------------------------------------------------------------------------------------------------------------------------------------|
| [Mathias Bynens](https://mathiasbynens.be/)                                                                                                       |

## Thanks to…

- @ptb and [his _macOS Setup_ repository](https://github.com/ptb/mac-setup)
- [Ben Alman](https://benalman.com/) and his [dotfiles repository](https://github.com/cowboy/dotfiles)
- [Cătălin Mariș](https://github.com/alrra) and his [dotfiles repository](https://github.com/alrra/dotfiles)
- [Gianni Chiappetta](https://butt.zone/) for sharing his
  [amazing collection of dotfiles](https://github.com/gf3/dotfiles)
- [Jan Moesen](https://jan.moesen.nu/) and his [ancient `.bash_profile`](https://gist.github.com/1156154) +
  [shiny_tilde_repository](https://github.com/janmoesen/tilde)
- Lauri ‘Lri’ Ranta for sharing
  [loads of hidden preferences](https://web.archive.org/web/20161104144204/http://osxnotes.net/defaults.html)
- [Matijs Brinkhuis](https://matijs.brinkhu.is/) and his [dotfiles repository](https://github.com/matijs/dotfiles)
- [Nicolas Gallagher](https://nicolasgallagher.com/) and his [dotfiles repository](https://github.com/necolas/dotfiles)
- [Sindre Sorhus](https://sindresorhus.com/)
- [Tom Ryder](https://sanctum.geek.nz/) and his [dotfiles repository](https://sanctum.geek.nz/cgit/dotfiles.git/about)
- [Kevin Suttle](http://kevinsuttle.com/) and his [dotfiles repository](https://github.com/kevinSuttle/dotfiles)
  and [macOS-Defaults project](https://github.com/kevinSuttle/macOS-Defaults), which aims to provide better
  documentation for [`~/.macos`](https://mths.be/macos)
- [Haralan Dobrev](https://hkdobrev.com/)
- [Marcel Bischoff](https://herrbischoff.com) and his
  [Awesome macOS Command Line](https://git.herrbischoff.com/awesome-macos-command-line/about/)
- [Maarten Billemont's Bash Guide](http://mywiki.wooledge.org/BashGuide)
- [Luiz Ferreira's dotfiles](https://github.com/lferreira/dotfiles)
- [Yann Bertrand's macOS defaults list](https://github.com/yannbertrand/macos-defaults)
- Anyone who [contributed a patch](https://github.com/mathiasbynens/dotfiles/contributors)
  or [made a helpful suggestion](https://github.com/mathiasbynens/dotfiles/issues)
