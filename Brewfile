# Install command-line tools using Homebrew.

# Install GNU core utilities (those that come with macOS are outdated).
# Don’t forget to add `$(brew --prefix coreutils)/libexec/gnubin` to `$PATH`.
brew 'coreutils'

# Install some other useful utilities like `sponge`.
brew 'moreutils'
# Install GNU `find`, `locate`, `updatedb`, and `xargs`, `g`-prefixed.
brew 'findutils'
# Install GNU `sed`, overwriting the built-in `sed`.
brew 'gnu-sed' #, args: ['with-default-names‘] #this option is not supported anymore
# Install Bash 4.
# Note: don’t forget to add `/usr/local/bin/bash` to `/etc/shells` before
# running `chsh`.
brew 'bash'
brew 'bash-completion2'

# Install `wget` with IRI support.
brew 'wget', args: ['with-iri']

# Install GnuPG to enable PGP-signing commits.
brew 'gnupg'

# Install more recent versions of some macOS tools.
brew 'vim', args: ['override-system-vi']
brew 'grep'
#brew 'openssh' # keep macOS default openssh because of the UseKeychain Option which cannot be provided by brew openssh
brew 'screen'

# Install font tools.
tap 'bramstein/webfonttools'
brew 'sfnt2woff'
brew 'sfnt2woff-zopfli'
brew 'woff2'

# Install some CTF tools; see https://github.com/ctfs/write-ups.
brew 'aircrack-ng'
brew 'bfg'
brew 'binutils'
brew 'binwalk'
brew 'cifer'
brew 'dex2jar'
brew 'dns2tcp'
brew 'fcrackzip'
brew 'foremost'
brew 'hashpump'
brew 'hydra'
brew 'john'
brew 'knock'
brew 'netpbm'
brew 'nmap'
brew 'pngcheck'
brew 'socat'
brew 'sqlmap'
brew 'tcpflow'
brew 'tcpreplay'
brew 'tcptrace'
brew 'ucspi-tcp '# `tcpserver` etc.
brew 'xpdf'
brew 'xz'

# Install other useful binaries.
brew 'ack'
brew 'atop'
brew 'buku'
brew 'composer'
#brew install exiv2
brew 'git'
brew 'git-lfs'
brew 'htop'
brew 'imagemagick', args:['with-webp']
brew 'jq'
brew 'lua'
brew 'lynx'
brew 'maven'
brew 'mpv'
brew 'node'
brew 'p7zip'
brew 'pigz'
brew 'pv'
brew 'rename'
brew 'rlwrap'
brew 'ssh-copy-id'
brew 'tree'
brew 'vbindiff'
brew 'yarn'
brew 'zopfli'
