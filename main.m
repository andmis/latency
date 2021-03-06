#include <math.h>
#include <stdio.h>
#include <time.h>

#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>
#import <Cocoa/Cocoa.h>

#define LEN(array) (sizeof(array)/sizeof(array[0]))

enum Modifiers {
  NO_MODIFIERS  = 0,
  CONTROL       = 1 << 1,
  OPTION        = 1 << 2,
  SHIFT         = 1 << 3,
  COMMAND       = 1 << 4,
  RIGHT_CONTROL = 1 << 5,
  RIGHT_OPTION  = 1 << 6,
  RIGHT_SHIFT   = 1 << 7,
  RIGHT_COMMAND = 1 << 8,
};

enum Modifiers kAllModifiers[] = {
  CONTROL,       OPTION,       SHIFT,       COMMAND,
  RIGHT_CONTROL, RIGHT_OPTION, RIGHT_SHIFT, RIGHT_COMMAND,
};

CGKeyCode modifierKeyCode(enum Modifiers modifier) {
  switch (modifier) {
    case CONTROL:       return kVK_Control;
    case OPTION:        return kVK_Option;
    case SHIFT:         return kVK_Shift;
    case COMMAND:       return kVK_Command;
    case RIGHT_CONTROL: return kVK_RightControl;
    case RIGHT_OPTION:  return kVK_RightOption;
    case RIGHT_SHIFT:   return kVK_RightShift;
    case RIGHT_COMMAND: return kVK_RightCommand;
    default:
      assert(false);
  }
}

struct Keystroke {
  CGKeyCode keyCode;
  enum Modifiers modifiers;
};

typedef struct Keystroke Keystrokes[];

struct Command {
  const char *name;
  int numKeystrokes;
  struct Keystroke *keystrokes;
};

#define COMMAND(NAME) { \
  .name = #NAME, \
  .numKeystrokes = LEN(NAME), \
  .keystrokes = NAME }

// For a list of keyCode constants, see:
// /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/System/Library/Frameworks/Carbon.framework/Versions/A/Frameworks/HIToolbox.framework/Versions/A/Headers/Events.h

Keystrokes typeLetterX = {
  { .keyCode = kVK_ANSI_X,
    .modifiers = SHIFT },
};

Keystrokes backspace = {
  { .keyCode = kVK_Delete,
    .modifiers = NO_MODIFIERS },
};

Keystrokes vimHorizontalSplit = {
  { .keyCode = kVK_ANSI_W,
    .modifiers = CONTROL },
  { .keyCode = kVK_ANSI_S,
    .modifiers = CONTROL },
};

Keystrokes vimCloseWindow = {
  { .keyCode = kVK_ANSI_W,
    .modifiers = CONTROL },
  { .keyCode = kVK_ANSI_C,
    .modifiers = NO_MODIFIERS },
};

// Type in an X, and then delete it.
struct Command commands[] = {
  COMMAND(typeLetterX),
  COMMAND(backspace),
};

/*
// Open and close a Vim split. Position the cursor over where the dividing status bar appears.
struct Command commands[] = {
  COMMAND(vimHorizontalSplit),
  COMMAND(vimCloseWindow),
};
*/

struct Color { float r, g, b; };

bool almost_same(struct Color c1, struct Color c2) {
  // XXX: https://github.com/vercel/hyper/issues/6509
  float manhattan_dist = fabs(c1.r-c2.r) + fabs(c1.g-c2.g) + fabs(c1.b-c2.b);
  return manhattan_dist < 5. / 255;
}

void print_color(struct Color c) {
  printf("r=%f, g=%f, b=%f\n", c.r, c.g, c.b);
}

CGDirectDisplayID kMainDisplayID;
CGEventSourceRef kEventSource;

// XXX: Sleep for 1 ms after every simulated key down/up event. If we don't do this then keystrokes with modifiers don't register correctly -- I'm not sure why.
const int kSleepTime_usec = 1000;

void down(CGKeyCode keyCode) {
  // NSLog(@"Down: %d", keyCode);
  usleep(kSleepTime_usec); // Conceptually we want to sleep a tiny bit between every pair of simulated key events because if we generate them too close together some stuff gets messed up. We sleep _before_ posting the event rather than after because after we post the last event of a command, the program whose latency we are measuring receives the event and begins working, so we want to start the clock as quickly after posting that last event as we can, and we start our clock after execute() returns.
  CGEventPost(kCGHIDEventTap, CGEventCreateKeyboardEvent(kEventSource, keyCode, true));
}

void up(CGKeyCode keyCode) {
  // NSLog(@"Up: %d", keyCode);
  usleep(kSleepTime_usec);
  CGEventPost(kCGHIDEventTap, CGEventCreateKeyboardEvent(kEventSource, keyCode, false));
}

void strike(struct Keystroke *keystroke) {
  for (int i = 0; i < LEN(kAllModifiers); ++i) {
    enum Modifiers mod = kAllModifiers[i];
    if (keystroke->modifiers & mod) down(modifierKeyCode(mod));
  }
  down(keystroke->keyCode);
  up(keystroke->keyCode);
  for (int i = LEN(kAllModifiers)-1; i >= 0; --i) {
    enum Modifiers mod = kAllModifiers[i];
    if (keystroke->modifiers & mod) up(modifierKeyCode(mod));
  }
}

void execute(struct Command *command) {
  for (int i = 0; i < command->numKeystrokes; ++i) {
    strike(&command->keystrokes[i]);
  }
}

int read_int(int argc, const char *argv[], int i) {
  if (!(0 <= i && i < argc)) {
    fprintf(stderr, "Error: argument required\n");
    exit(-1);
  }
  int val;
  int ret = sscanf(argv[i], "%d", &val);
  if (ret != 1) {
    fprintf(stderr, "Error: integer argument required\n");
    exit(-2);
  }
  return val;
}

int main(int argc, const char *argv[]) {
  int skip = 0; // Number of cycles to skip when printing. Useful when getting things set up at the beginning of a test run.
  int cycles = -1; // Number of cycles to run in all, after the skipped cycles. Every command will be executed this many times. Negative means to run forever.
  bool baseline = false; // Don't send any keyboard commands, just poll the pixel under the cursor to establish how many milliseconds that takes.

  for (int i = 1; i < argc; ++i) {
    if (!strcmp(argv[i], "--skip")) skip = read_int(argc, argv, ++i);
    if (!strcmp(argv[i], "--cycles")) cycles = read_int(argc, argv, ++i);
    if (!strcmp(argv[i], "--baseline")) baseline = true;
  }

  kMainDisplayID = CGMainDisplayID();
  kEventSource = CGEventSourceCreate(kCGEventSourceStateHIDSystemState);
  // NSLog(@"Main display id=%d", kMainDisplayID);

  // We cycle through the commands, executing the next one every time the color under the cursor changes.
  int cycle = 1;
  int index = 0;
  struct Color lastColor = {.r = -1, .g = -1, .b = -1};
  struct timespec start;
  clock_gettime(CLOCK_MONOTONIC, &start);

  while (cycles < 0 || cycle <= skip + cycles) {
    @autoreleasepool {
      CGPoint cursor = CGEventGetLocation(CGEventCreate(NULL));
      // NSLog(@"Mouse pos: (%f, %f)", cursor.x, cursor.y);
      CGRect rect = CGRectMake(cursor.x, cursor.y, 1, 1);
      CGImageRef image = CGDisplayCreateImageForRect(kMainDisplayID, rect);
      NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithCGImage:image];
      CGImageRelease(image);
      NSColor *nsColor = [bitmap colorAtX:0 y:0];
      // NSLog(@"%@", nsColor);
      struct Color color = {
        .r = [nsColor redComponent],
        .g = [nsColor greenComponent],
        .b = [nsColor blueComponent]
      };
      if (baseline || !almost_same(lastColor, color)) {
        // print_color(color);
        struct timespec now;
        clock_gettime(CLOCK_MONOTONIC, &now);
        unsigned usec = 1e6*(now.tv_sec-start.tv_sec) + (int)(1e-3*(now.tv_nsec-start.tv_nsec));
        if (cycle > skip) {
          const char *name = baseline ? "baseline" : commands[index].name;
          printf("%s %.2f\n", name, (float)usec/1e3);
        }
        fflush(stdout);
        if (!baseline) execute(&commands[index]);
        index++;
        if (baseline || index == LEN(commands)) {
          index = 0;
          cycle++;
        }
        clock_gettime(CLOCK_MONOTONIC, &start);
      }
      lastColor = color;
      [bitmap release];
    }
  }
  return 0;
}
