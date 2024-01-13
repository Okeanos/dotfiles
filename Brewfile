# Configure taps
tap "homebrew/bundle"
tap "homebrew/cask-versions"
tap "homebrew/services"
tap "johanhaleby/kubetail"
# Configure where our applications go
cask_args appdir: "/Applications"

brew "bash"
brew "bash-completion@2"
#brew "bats-core"
brew "coreutils"
brew "curl"
brew "dive"
#brew "editorconfig-checker"
brew "findutils"
brew "gh"
brew "git"
brew "git-lfs"
brew "gnu-sed"
brew "gnupg", link: false # conflicts with cask "gpg-suite-no-mail"
brew "go"
brew "grep"
#brew "hadolint"
brew "htop"
brew "jq"
brew "kubectx"
brew "kubernetes-cli"
brew "kubetail"
brew "mas"
brew "maven"
brew "maven-completion"
brew "moreutils"
brew "netcat"
brew "node"
brew "pigz" # https://github.com/moby/moby/pull/35697
#brew "shellcheck"
brew "starship"
brew "stow"
brew "tree"
brew "vim"
brew "wget"
#brew "yamllint"
brew "yarn"
brew "yarn-completion"
brew "yq"

cask "adobe-acrobat-reader"
cask "docker"
cask "firefox"
cask "google-chrome"
cask "gpg-suite-no-mail"
cask "iterm2"
cask "jetbrains-toolbox"
cask "keepassxc"
cask "powershell"
cask "qlmarkdown", args: { no_quarantine: true }
cask "rectangle"
cask "sourcetree"
cask "suspicious-package"
cask "syntax-highlight", args: { no_quarantine: true }
cask "temurin17"
cask "temurin21"
cask "the-unarchiver"
cask "visual-studio-code"

# Install Mac App Store applications
# See https://github.com/mas-cli/mas
# requires an Apple ID
mas "AdGuard for Safari", id: 1440147259
mas "Consent-O-Matic", id: 1606897889
mas "Keynote", id: 409183694
mas "Numbers", id: 409203825
mas "Pages", id: 409201541

# Install Visual Studio Code extensions
vscode "asciidoctor.asciidoctor-vscode"
vscode "ban.spellright"
vscode "DotJoshJohnson.xml"
vscode "EditorConfig.EditorConfig"
vscode "github.vscode-github-actions"
#vscode "jetmartin.bats"
vscode "ms-azuretools.vscode-docker"
vscode "ms-vscode.powershell"
vscode "redhat.vscode-yaml"
vscode "tamasfe.even-better-toml"
vscode "timonwong.shellcheck"
vscode "yzhang.markdown-all-in-one"
