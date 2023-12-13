# Verify dotfiles are set up as expected

You can use the included [bats](https://github.com/bats-core/bats-core) scripts to verify the dotfiles (as shipped) have
been installed as expected.

```bash
npm install # required to use the bats-* libraries
npm run test # or bats . in case you want to use bats natively
```

In case you want to override a couple of things in the tests, e.g. say the
[Brewfile](https://github.com/Homebrew/homebrew-bundle) location, you can do that:

```bash
HOMEBREW_BUNDLE_FILE=~/another/location/Brewfile bats .
```
