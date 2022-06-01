# Measuring input latency

This is a simple command-line tool for measuring the input latency of graphical and terminal apps on macOS. It generates keystrokes and measures the time it takes for the screen to react. You could use this to measure the input latency for apps like: terminal emulators (iTerm, Terminal.app, kitty, alacritty), shells (Bash, Zsh, fish), text editors / IDEs (Vim, Emacs, VS Code, Sublime), etc.

## Building

``` bash
clang -framework Foundation -framework Cocoa main.m
./a.out
```

## Running

By default, the tool will generate X and ⌫ keystrokes. After sending a keystroke, it will poll the screen pixel under the cursor until it changes color – this produces a single latency measurement. Then it will send the next keystroke, and so on.

Basic usage:
- Run the following command:
  ``` bash
  ./a.out --skip 50 | ./stats.py
  ```
- Focus the app whose latency you would like to measure.
- Put the mouse cursor under the keyboard cursor. Play around with the mouse cursor position until the keystroke-measurement-keystroke-measurement cycle kicks in.

## Configuring

You can customize the generated key sequence using the `commands` variable in `main.m`. Look there for examples.

