# Configure taps
tap "CtrlSpice/homebrew-otel-desktop-viewer" # is not up to date with source https://github.com/CtrlSpice/homebrew-otel-desktop-viewer/blob/main/otel-desktop-viewer.rb (v0.1.2 vs v0.1.4 latest releases)
tap "equinix-labs/otel-cli"
tap "johanhaleby/kubetail"
# Configure where our applications go
cask_args appdir: "/Applications"

brew "bash"
brew "bash-completion@2"
brew "bat"
#brew "bats-core"
brew "coreutils"
brew "csvlens"
brew "curl"
brew "dive"
#brew "editorconfig-checker"
brew "findutils"
brew "gh"
brew "git"
brew "git-delta"
brew "git-lfs"
brew "gitleaks"
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
#brew "markdownlint-cli2"
brew "mas"
brew "maven"
brew "maven-completion"
brew "moreutils"
brew "netcat"
brew "node"
brew "opentofu"
brew "otel-cli"
brew "otel-desktop-viewer" # maybe replace with Jaeger-All-In-One? See https://github.com/open-telemetry/community/issues/1515
brew "pigz" # See https://github.com/moby/moby/pull/35697 (may be irrelevant for macOS)
brew "ripgrep"
#brew "shellcheck"
#brew "shfmt"
brew "starship"
brew "stow"
#brew "talisman"
#brew "taplo"
brew "tree"
brew "trurl"
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
cask "temurin@17"
cask "temurin@21"
cask "the-unarchiver"
cask "visual-studio-code"
cask "xattred"

# Install Mac App Store applications
# See https://github.com/mas-cli/mas
# requires an Apple ID
mas "AdGuard for Safari", id: 1440147259
mas "Consent-O-Matic", id: 1606897889
mas "Keynote", id: 409183694
mas "Numbers", id: 409203825
mas "Pages", id: 409201541
#mas "uBlacklist for Safari", id: 1547912640 # can be covered by AdGuard instead using a Custom Filter

# Install Visual Studio Code extensions
vscode "asciidoctor.asciidoctor-vscode"
vscode "ban.spellright"
vscode "dotjoshjohnson.xml"
vscode "editorconfig.editorconfig"
vscode "github.vscode-github-actions"
vscode "hashicorp.terraform"
#vscode "jetmartin.bats"
vscode "mkhl.shfmt"
vscode "ms-azuretools.vscode-docker"
vscode "ms-vscode.powershell"
vscode "redhat.vscode-xml"
vscode "redhat.vscode-yaml"
vscode "tamasfe.even-better-toml"
vscode "timonwong.shellcheck"
vscode "yzhang.markdown-all-in-one"
