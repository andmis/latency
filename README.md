# Measuring input latency

This is a simple command-line tool for measuring the input latency of graphical and terminal apps on macOS. It generates keystrokes and measures the time it takes for the screen to react. You could use this to measure the input latency for apps like: terminal emulators (iTerm, Terminal.app, kitty, alacritty), shells (Bash, Zsh, fish), text editors / IDEs (Vim, Emacs, VS Code, Sublime), etc.

## Building

``` bash
clang -framework Foundation -framework Cocoa main.m
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

## Example output

```
repos/latency$ ./a.out --skip 100 | ./stats.py
commands_seen=200
NAME        | MIN   | MEAN  | MAX
backspace   | 11.04 | 11.76 | 24.17
typeLetterX | 10.02 | 14.3  | 26.29

commands_seen=400
NAME        | MIN   | MEAN  | MAX
backspace   | 10.37 | 12.16 | 28.49
typeLetterX | 5.91  | 14.31 | 26.41

commands_seen=600
NAME        | MIN  | MEAN  | MAX
backspace   | 6.9  | 12.18 | 28.49
typeLetterX | 5.91 | 14.33 | 26.41

commands_seen=800
NAME        | MIN  | MEAN  | MAX
backspace   | 6.9  | 12.18 | 28.49
typeLetterX | 5.47 | 14.3  | 26.41
```

## Configuring

You can customize the generated key sequence using the `commands` variable in `main.m`. Look there for examples.

