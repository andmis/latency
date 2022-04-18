#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

int main(int argc, const char *argv[]) {
  CGDirectDisplayID mainDisplayID = CGMainDisplayID();
  CGSize mainDisplaySize = CGDisplayBounds(mainDisplayID).size;
  NSLog(@"Main display id=%d, (width, height)=(%f, %f)", mainDisplayID, mainDisplaySize.width, mainDisplaySize.height);

  while (true) {
    @autoreleasepool {
      // Grab the current mouse location.
      NSPoint mouseLoc = [NSEvent mouseLocation];
      CGPoint cgPoint = NSPointToCGPoint(mouseLoc);
      // It seems like we need to flip the y coordinate -- the coordinate systems don't agree, or something. 
      cgPoint.y = mainDisplaySize.height - cgPoint.y;
      // NSLog(@"Mouse pos: (%f, %f)", cgPoint.x, cgPoint.y);

      // Grab the display(s) with the mouse location.
      const int maxDisplays = 10;
      uint32_t count = 0;
      CGDirectDisplayID displayForPoint[maxDisplays];
      CGError error = CGGetDisplaysWithPoint(cgPoint, maxDisplays, displayForPoint, &count);
      if (error != kCGErrorSuccess) {
        NSLog(@"Error: %d", error);
        continue;
      } else if (count == 0) {
        NSLog(@"Error: could not find a display with the cursor, wat");
        continue;
      }
      // XXX: What happens if the cursor is on multiple displays, for example if display mirroring is on?
      CGDirectDisplayID displayID = displayForPoint[0];
      // NSLog(@"Display ID with cursor: %d", displayID);

      // Grab the color at the pixel under the cursor.
      CGRect rect = CGRectMake(cgPoint.x, cgPoint.y, 1, 1);
      CGImageRef image = CGDisplayCreateImageForRect(displayID, rect);
      NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithCGImage:image];
      CGImageRelease(image);
      NSColor *color = [bitmap colorAtX:0 y:0];
      NSLog(@"%@", color);
      [bitmap release];
    }
  }
  return 0;
}
