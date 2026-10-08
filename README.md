# nix-apple-fonts

An nix package for fonts distributed by Apple Inc at https://developer.apple/fonts/ .

## Usage

```nix
{
  inputs = {
    apple-fonts.url = "github:mityu/nix-apple-fonts";
  };

  outputs = { apple-fonts, ... }:
  {
    # Use apple-fonts.sf-mono, etc
  };
}
```

## Package list

- `default`: Same as `full`
- `full`: All set of the following fonts
- `sf-pro`: The SF Pro font
- `sf-compact`: The SF Compact font
- `sf-mono`: The SF Mono font
- `newyork`: The New York font
