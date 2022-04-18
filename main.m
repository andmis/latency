#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

typedef struct { float r, g, b; } Color;

bool same(Color c1, Color c2) {
  return c1.r == c2.r && c1.g == c2.g && c1.b == c2.b;
}

int main(int argc, const char *argv[]) {
  CGDirectDisplayID mainDisplayID = CGMainDisplayID();
  // NSLog(@"Main display id=%d", mainDisplayID);
  CGEventSourceRef eventSource = CGEventSourceCreate(kCGEventSourceStateHIDSystemState);

  CGKeyCode backspace = 51;
  CGKeyCode x = 7;
  CGKeyCode nextKeyCode = x;
  Color lastColor = {.r = -1, .g = -1, .b = -1};
  while (true) {
    @autoreleasepool {
      CGPoint cursor = CGEventGetLocation(CGEventCreate(NULL));
      // NSLog(@"Mouse pos: (%f, %f)", cursor.x, cursor.y);
      CGRect rect = CGRectMake(cursor.x, cursor.y, 1, 1);
      CGImageRef image = CGDisplayCreateImageForRect(mainDisplayID, rect);
      NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithCGImage:image];
      CGImageRelease(image);
      NSColor *nsColor = [bitmap colorAtX:0 y:0];
      // NSLog(@"%@", nsColor);
      Color color = {
        .r = [nsColor redComponent],
        .g = [nsColor greenComponent],
        .b = [nsColor blueComponent]
      };
      if (!same(lastColor, color)) {
        CGEventPost(kCGHIDEventTap, CGEventCreateKeyboardEvent(eventSource, nextKeyCode, true));
        CGEventPost(kCGHIDEventTap, CGEventCreateKeyboardEvent(eventSource, nextKeyCode, false));
        nextKeyCode = (nextKeyCode == x ? backspace : x);
      }
      lastColor = color;
      [bitmap release];
    }
  }
  return 0;
}
