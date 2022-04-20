# Measuring input latency

## Building

``` bash
clang -framework Foundation -framework Cocoa main.m
./a.out
```

## Running

``` bash
./a.out | ./stats.py
```
