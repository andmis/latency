#!/usr/bin/env python3

from collections import defaultdict, deque


def tabulate(rows):
  def width(x):
    return len(x) if x else 0
  widths = [max(width(x) for x in col) for col in zip(*rows)]
  def pad(x, target_width):
    return x + ' '*(target_width - width(x))
  for row in rows:
    print(' | '.join(pad(x, target_width) for x, target_width in zip(row, widths)))
  print('')


def mean(xs):
  return sum(xs) / len(xs)


def row_data(name, latencies):
  def stringify(f):
    return str(round(f, 2))
  return [name, stringify(min(latencies)), stringify(mean(latencies)), stringify(max(latencies))]


def main():
  num_commands_in_rolling_window = 1000
  print_frequency = 200
  latency = defaultdict(lambda: deque(maxlen=num_commands_in_rolling_window))
  def print_summary(commands_seen):
    print(f'{commands_seen=}')
    tabulate([
      ['NAME', 'MIN', 'MEAN', 'MAX'],
      *(row_data(command_name, latency[command_name])
        for command_name in sorted(latency.keys()))
    ])
  try:
    commands_seen = 1
    while True:
      command_name, ms = input().split()
      ms = float(ms)
      latency[command_name].append(ms)
      if commands_seen % print_frequency == 0:
        print_summary(commands_seen)
      commands_seen += 1
  except EOFError:
    print('Done!')


if __name__ == '__main__':
  main()
