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

bool same(struct Color c1, struct Color c2) {
  return c1.r == c2.r && c1.g == c2.g && c1.b == c2.b;
}

CGDirectDisplayID kMainDisplayID;
CGEventSourceRef kEventSource;

// XXX: Sleep for 1 ms after every simulated key down/up event. If we don't do this then keystrokes with modifiers don't register correctly -- I'm not sure why.
const int kSleepTime_usec = 1000;

void down(CGKeyCode keyCode) {
  // NSLog(@"Down: %d", keyCode);
  CGEventPost(kCGHIDEventTap, CGEventCreateKeyboardEvent(kEventSource, keyCode, true));
  usleep(kSleepTime_usec);
}

void up(CGKeyCode keyCode) {
  // NSLog(@"Up: %d", keyCode);
  CGEventPost(kCGHIDEventTap, CGEventCreateKeyboardEvent(kEventSource, keyCode, false));
  usleep(kSleepTime_usec);
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

int main(int argc, const char *argv[]) {
  kMainDisplayID = CGMainDisplayID();
  kEventSource = CGEventSourceCreate(kCGEventSourceStateHIDSystemState);
  // NSLog(@"Main display id=%d", kMainDisplayID);

  // We cycle through the commands, executing the next one every time the color under the cursor changes.
  int index = 0;
  struct Color lastColor = {.r = -1, .g = -1, .b = -1};
  struct timespec start;
  clock_gettime(CLOCK_MONOTONIC, &start);

  while (true) {
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
      if (!same(lastColor, color)) {
        struct timespec now;
        clock_gettime(CLOCK_MONOTONIC, &now);
        unsigned usec = 1e6*(now.tv_sec-start.tv_sec) + (int)(1e-3*(now.tv_nsec-start.tv_nsec));
        printf("%s %ld\n", commands[index].name, lround((float)usec/1e3));
        execute(&commands[index]);
        index = (index+1) % LEN(commands);
        clock_gettime(CLOCK_MONOTONIC, &start);
      }
      lastColor = color;
      [bitmap release];
    }
  }
  return 0;
}
